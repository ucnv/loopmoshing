module Loopmoshing
  class Base
    attr_accessor :fps, :concat_times, :max_length, :max_width

    def initialize max_length = 7, max_width = 500, fps = 15
      @fps = fps
      @max_length = max_length
      @max_width = max_width
      @concat_times = 3
    end

    def make infile, outdir
      dir = Pathname.new outdir
      tmpavi = dir.join('tmp.avi').to_s
      # check if the file is valid
      cmd = Cocaine::CommandLine.new 'ffmpeg', '-i :infile -vf "scale=500:-1" -an -t :length -r :fps -vcodec mpeg4 :outfile'
      cmd.run infile: infile.path, fps: @fps.to_s, length: @max_length.to_s, outfile: tmpavi

      # aviglitch removes keyframes
      a = AviGlitch.open tmpavi
      a.remove_all_keyframes!
      d = a.frames * @concat_times
      d.to_avi.output tmpavi

      # ffmpeg extract avi to png files
      cmd = Cocaine::CommandLine.new 'ffmpeg', '-i :infile -an -y -f image2 :outfile'
      cmd.run infile: tmpavi, outfile: dir.join('%03d.png').to_s

      pngs = Dir.glob dir.join('*.png')
      pngs.each_with_index do |p, i|
        File.unlink p if i < (@concat_times - 1) * pngs.size / @concat_times
      end

      # imagemagick concat png files to gif
      result = dir.join 'loopmoshing.gif'
      cmd = Cocaine::CommandLine.new 'convert', '-layers optimize -delay :delay :infile :outfile'
      cmd.run infile: dir.join('*.png').to_s, delay: "1x#{@fps}", outfile: result.to_s

      result
    end
  end
end

