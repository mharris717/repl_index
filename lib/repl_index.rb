require 'mharris_ext'

class ReplIndex
  include FromHash
  class << self
    fattr(:instance) { new }
    def method_missing(sym,*args,&b)
      instance.send(sym,*args,&b)
    end
  end
  #fattr(:dirs) { ["c:/code/dw_gems/combine","c:/code/sql_tools"] }
  fattr(:dirs) { [File.expand_path(Dir.getwd)] }
  fattr(:exts) { %w(rb js ktr) }
  fattr(:addl_globs) do
    res = []
    #res << "c:/code/sql_tools/views/*.sql"
    #res << "C:/Documents and Settings/mharris.TRIBE/Desktop/*.sql"
    #res << "c:/code/dw_gems/combine/**/*.sql"
    res
  end
  def globs
    ext_str = "{" + exts.join(",") + "}"
    dirs.map { |dir| "#{dir}/**/*.#{ext_str}" } + addl_globs
  end
  fattr(:files) do
    globs.map do |glob|
      Dir[glob]
    end.flatten
  end
  fattr(:bodies) do
    files.inject({}) do |h,f|
      h.merge(f.downcase => File.read(f))
    end
  end
  def add_file(f)
    f = f.downcase
    return if bodies[f]
    return unless f =~ /\.rb$/i || f =~ /rake/i
    bodies[f] = File.read(f)
  end
  def add_all_loaded!
    $".each { |f| add_file(f) }
  end
  def include_file_in_search?(f,ops)
    return false if ops[:ext] && f.split(".").last.downcase != ops[:ext].to_s.downcase
    true
  end
  def find(strs,ops={})
    res = []
    strs = [strs].flatten
    bodies.each do |f,body|
      res << f if strs.all? { |str| include_file_in_search?(f,ops) && (f =~ /#{str}/i || body =~ /#{str}/i) }
    end
    #res#.map { |x| x.gsub("#{dir}","CB") }
    res
  end
  def open!(f)
    #cmd = "\"c:\\progra~1\\sublime text 2\\sublime_text.exe\" #{f}"
    #ec cmd
    dir = File.dirname(f).gsub("/","\\")
    `explorer "#{dir}"`
  end
  def green(*args); puts(*args); end
  def red(*args); puts(*args); end

  class << self
    def fcf(*args)
      ops = args.last.kind_of?(Hash) ? args.pop : {}
      strs = [args].flatten.map { |x| x.to_s }
      add_all_loaded!
      files = ReplIndex.find(strs,ops)
      puts "\n#{green(files.size.to_s)} matches for #{green(strs.inspect)}"
      files.each_with_index { |x,i| puts "#{i+1}. #{x}" }
      puts "\n"

      if ops[:choose]
        i = STDIN.gets.to_i
        ReplIndex.open! files[i-1] if i > 0
      end

      nil
    end
  end
end

def fcf(str,ext=:rb)
  ReplIndex.fcf(str, :ext => ext)
end

def fcfa(str)
  ReplIndex.fcf(str)
end








