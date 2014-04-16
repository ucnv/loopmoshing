# encoding: utf-8
require 'bundler'
Bundler.require
require 'digest/md5'
require 'pathname'
require 'tmpdir'

configure do
  set :fps, 15
  set :concat_times, 3
  set :max_length, 7
  set :max_width, 500
end

before do
  s3 = AWS::S3.new(
    access_key_id:      ENV['AWS_S3_KEY_ID'],
    secret_access_key:  ENV['AWS_S3_SECRET_KEY']
  )
  @bucket = s3.buckets[ENV['AWS_S3_BUCKET']]
end

helpers do
  def filename hash
    'files/' + hash + '.gif'
  end

end

get '/*' do
  hash = params[:splat].first
  pass if hash.start_with? '_'

  if hash.empty?
    @gif = @bucket.objects.with_prefix('files/').collect(&:public_url).select{|u|
      u.to_s =~ /gif$/
    }.shuffle.first
    @gif = 'sample.gif' if Sinatra::Base.development?
  else
    @gif = @bucket.objects[filename(hash)].public_url
  end

  halt 404, slim(:'404') if @gif.to_s.empty?
  slim :index, pretty: true
end

post '/upload' do
  target = params[:movie][:tempfile]
  logger.info target

  hash = Digest::MD5.hexdigest(Time.now.to_f.to_s)
  name = 'files/' + hash + '.gif'

  # This block is not tested. It shoukd ready to throw more exceptions.
  Dir.mktmpdir do |d|
    dir = Pathname.new d
    tmpavi = dir.join('tmp.avi').to_s
    # check if the file is valid
    cmd = Cocaine::CommandLine.new 'ffmpeg', '-i :infile -vf "scale=500:-1" -an -t :length -r :fps -vcodec mpeg4 :outfile'
    cmd.run infile: target.path, fps: settings.fps.to_s, length: settings.max_length.to_s, outfile: tmpavi

    # aviglitch removes keyframes
    a = AviGlitch.open tmpavi
    a.remove_all_keyframes!
    d = a.frames * settings.concat_times
    d.to_avi.output tmpavi

    # ffmpeg extract avi to png files
    cmd = Cocaine::CommandLine.new 'ffmpeg', '-i :infile -an -y -f image2 :outfile'
    cmd.run infile: tmpavi, outfile: dir.join('%03d.png').to_s

    pngs = Dir.glob dir.join('*.png')
    pngs.each_with_index do |p, i|
      File.unlink p if i < (settings.concat_times - 1) * pngs.size / settings.concat_times
    end

    # imagemagick concat png files to gif
    result = dir.join 'o.gif'
    cmd = Cocaine::CommandLine.new 'convert', '-layers optimize -delay :delay :infile :outfile'
    cmd.run infile: dir.join('*.png').to_s, delay: "1x#{settings.fps}", outfile: result.to_s

    object = @bucket.objects[name]
    object.write result
    object.acl = :public_read
  end

  redirect to("/%s" % hash)
end


__END__

@@ layout

doctype html
head
  meta charset="utf-8"
  title Loopmoshing
  link rel="stylesheet" href="/a.css"
  script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"
  script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js"
  script src="/a.js"
body
  == yield


@@ index

#bg.loading data-src="#{@gif}"
h1 Loopmoshing
a.nav.show.about href="#about" About this site
a.nav.show.upload href="#upload" Upload movie
a.nav.view href="#{@gif}" View image
#about.popup
  | Loopmoshing is a web tool to generate short and looping datamoshing movie
    that coverted as animated GIF.
  br
  | You can generate your own looping-datamoshing-GIF from the top 
    right corner of this screen.
  br
  | Internally it uses the library 
  a href="http://ucnv.github.io/aviglitch/" AviGlitch
  '  which is made by UCNV.
#upload.popup
  .errors
  form method="post" action="/upload" enctype="multipart/form-data" name="upload"
    input type="file" name="movie"
    br
    input type="submit" name="submit" value="Upload"
  p.notice
    | The file must be a movie file.
    br
    | The file size must be less than ?M.
      It will trim to first #{settings.max_length}s if the video is longer than #{settings.max_length}s.
    br
    | Please notice that you can't delete the generated file once it's processed.
    br
    | The process might take a few minutes.


@@ 404
p Not found

