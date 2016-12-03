class Codenize::Client
  def initialize(options = {})
    @options = options
    @logger = Codenize::Logger.instance
  end

  def generate
    FileUtils.chdir(@options[:dir]) do
      name = @options[:name]

      if File.exist?(name)
        raise "directory already exists: #{name}"
      end

      Bundler.with_clean_env do
        sh 'bundle', 'gem', name or raise 'bundle gem faild'
      end

      FileUtils.chdir(name) do
        update_files(name)
        create_files(name)
        @logger.info 'Adding generated code to git repo'
        sh 'git', 'add', '.'
      end
    end
  end

  private

  def update_files(name)
    update!("#{name}.gemspec") do |content|
      content.sub!(/end\z/, ERBh.erbh(<<-EOS, aws: @options[:aws]))
  <%- if @aws -%>
  spec.add_dependency 'aws-sdk'
  <%- end -%>
  spec.add_dependency 'diffy'
  spec.add_dependency 'dslh', '>= 0.4.0'
  spec.add_dependency 'hashie'
  #spec.add_dependency 'parallel'
  #spec.add_dependency 'pp_sort_hash'
  spec.add_dependency 'term-ansicolor'
  spec.add_dependency 'thor'
end
      EOS
    end
  end

  def create_files(name)
    base_dir = File.expand_path('../../template', __FILE__)

    Dir.glob("#{base_dir}/**/*.erb") do |tmpl|
      path = tmpl.sub(%r|\A#{Regexp.escape(base_dir)}/|, '').split('/').map {|d|
        replace_name(d, name)
      }.join('/').sub(/\.erb\z/, '')

      @logger.info("      create #{path}")

      FileUtils.mkdir_p(File.dirname(path))

      open(path, 'wb') do |file|
        file.puts ERBh.erbh(File.read(tmpl),
          name: name,
          const_name: Bundler::Thor::Util.camel_case(name),
          aws: @options[:aws],
        ).strip
      end

      if path =~ %r|\Aexe/|
        FileUtils.chmod(0755, path)
      end
    end
  end

  def sh(*args)
    status = nil

    Open3::popen3(*args) do |stdin, stdout, stderr, wait_thr|
      [stdin, stdout, stderr].each {|io| io.sync = true }
      errmsg = ''

      thr_out = Thread.start do
        stdout.each do |line|
          $stdout.print line
        end
      end

      thr_err = Thread.start do
        stderr.each do |line|
          $stderr.print line
          errmsg << line
        end
      end

      wait_thr.join
      thr_out.join
      thr_err.join
      status = wait_thr.value
    end

    status.success?
  end

  def update!(path)
    @logger.info("      update #{path}")

    content = File.read(path)
    yield(content.strip!)

    open(path, 'wb') do |file|
      file.puts content.strip
    end
  end

  def replace_name(path, name)
    path.sub(/\A_name\b/, name)
  end
end
