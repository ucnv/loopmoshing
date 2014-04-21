module Loopmoshing
  class Cli < Thor
    desc 'generate', 'Make loopmoshing gif'

    def generate infile, outfile = nil
      outfile = outfile.nil? ? Pathname.new(infile).dirname.join('out.gif') : Pathname.new(outfile)
      open(infile, 'r:ASCII-8BIT') do |f|
        Dir.mktmpdir do |d|
          result = Base.new.make f, d
          FileUtils.cp result, outfile
        end
      end
    end
  end
end
