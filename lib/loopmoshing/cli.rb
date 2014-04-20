module Loopmoshing
  class Cli < Thor
    desc 'generate', 'Make loopmoshing gif'

    def generate infile, outdir = 'tmp'
      open(infile, 'r:ASCII-8BIT') do |f|
        Base.new.make f, outdir
      end
    end
  end
end
