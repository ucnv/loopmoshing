require 'spec_helper'

describe Loopmoshing do
  it 'generates the file with correct frames size' do
    length = (5..10).to_a.shuffle.first
    fps = (10..20).to_a.shuffle.first

    fixture = Pathname.new(__FILE__).dirname.join('fixtures')
    infile = fixture.join 'in.mp4'
    outfile = fixture.join 'out.gif'
    [true, false].each do |use_imagemagick|
      open(infile, 'r:ASCII-8BIT') do |f|
        Dir.mktmpdir do |d|
          maker = Loopmoshing::Base.new
          maker.max_length = length
          maker.max_width = 100
          maker.fps = fps
          maker.use_imagemagick = use_imagemagick
          begin
          result = maker.make f, d
          rescue
            FileUtils.cp Pathname.new(d).join('*'), '/tmp/holo/'
          end
          FileUtils.cp result, outfile
        end
      end
      expected = [length * fps - 3, length * fps]
      cmd = Cocaine::CommandLine.new 'identify', ':in'
      info = cmd.run in: outfile.to_s
      expect(info.split(/\n/).size).to be_between(expected.shift, expected.shift)
      FileUtils.rm outfile
    end
  end
end
