require 'spec_helper'

describe Loopmoshing do
  it 'generates the file with correct frames size' do
    length = 8#(5..10).to_a.shuffle.first
    fps = 15#(10..20).to_a.shuffle.first

    fixture = Pathname.new(__FILE__).dirname.join('fixtures')
    infile = fixture.join 'in.mp4'
    outfile = fixture.join 'out.gif'
    open(infile, 'r:ASCII-8BIT') do |f|
      Dir.mktmpdir do |d|
        result = Loopmoshing::Base.new(length, 100, fps).make f, d
        FileUtils.cp result, outfile
      end
    end
    expected = length * fps - 3
    cmd = Cocaine::CommandLine.new 'identify', ':in'
    info = cmd.run in: outfile.to_s
    expect(info.split(/\n/).size).to eq(expected)
    FileUtils.rm outfile
  end
end
