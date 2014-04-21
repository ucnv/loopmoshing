module Loopmoshing
  class Base
    attr_accessor :fps, :concat_times, :max_length, :max_width

    def initialize max_length = 7, max_width = 500, fps = 15
      @fps = fps
      @max_length = max_length
      @max_width = max_width
      @concat_times = 3
    end

    def make infile, outdir, use_imagemagick = false
      dir = Pathname.new outdir
      tmpavi = dir.join('tmp.avi').to_s
      # check if the file is valid
      cmd = Cocaine::CommandLine.new 'ffmpeg', '-i :infile -vf "scale=500:-1" -g 9000 -an -t :length -r :fps -vcodec mpeg4 :outfile'
      cmd.run infile: infile.path, fps: @fps.to_s, length: @max_length.to_s, outfile: tmpavi

      # aviglitch removes keyframes
      a = AviGlitch.open tmpavi
      a.remove_all_keyframes!
      len = a.frames.size
      d = a.frames * @concat_times
      d.to_avi.output tmpavi

      result = dir.join 'loopmoshing.gif'

      # using imagemagick, nice quality but very slow
      if use_imagemagick
        # ffmpeg extract avi to png files
        cmd = Cocaine::CommandLine.new 'ffmpeg', '-i :infile -an -y -f image2 :outfile'
        cmd.run infile: tmpavi, outfile: dir.join('%03d.png').to_s

        pngs = Dir.glob dir.join('*.png')
        pngs.sort.each_with_index do |p, i|
          File.unlink p if i <= (@concat_times - 1) * pngs.size / @concat_times
        end

        # imagemagick concat png files to gif
        cmd = Cocaine::CommandLine.new 'convert', '-layers optimize -delay :delay :infile :outfile'
        cmd.run infile: dir.join('*.png').to_s, delay: "1x#{@fps}", outfile: result.to_s
      else
        l = len / (@fps - 1)
        cmd = Cocaine::CommandLine.new 'ffmpeg', '-i :infile -ss :start_at -t :length -an -y :outfile'
        cmd.run infile: tmpavi, length: l.to_s, start_at: (l * 2).to_s , outfile: result.to_s
      end

      result
    end
  end
end

