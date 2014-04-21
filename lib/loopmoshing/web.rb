module Loopmoshing
  class Web < Sinatra::Base

    enable :inline_templates
    set :root, Pathname.new(File.dirname(__FILE__)).join('..', '..')

    set :bucket, Proc.new {
      s3 = AWS::S3.new(
        access_key_id:      ENV['AWS_S3_KEY_ID'],
        secret_access_key:  ENV['AWS_S3_SECRET_KEY']
      )
      s3.buckets[ENV['AWS_S3_BUCKET']]
    }

    helpers do
      def filename hash
        'files/' + hash + '.gif'
      end
    end

    get '/*' do
      hash = params[:splat].first
      pass if hash.start_with? '_'

      if hash.empty?
        @gif = settings.bucket.objects.with_prefix('files/').collect(&:public_url).select{|u|
          u.to_s =~ /gif$/
        }.shuffle.first
          @gif = 'sample.gif' if Sinatra::Base.development?
      else
        @gif = settings.bucket.objects[filename(hash)].public_url
      end

      halt 404, slim(:'404') if @gif.to_s.empty?
      slim :index, pretty: true
    end

    post '/upload' do
      hash = Digest::MD5.hexdigest(Time.now.to_f.to_s)
      file = params[:movie][:tempfile]
      Dir.mktmpdir do |tmpdir|
        result = Base.new.make file, tmpdir
        name = filename hash
        object = settings.bucket.objects[name]
        object.write result
        object.acl = :public_read
      end

      redirect to("/%s" % hash)
    end

  end
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
  .cover
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
      It will trim to first 7s if the video is longer than 7s.
    br
    | Please notice that you can't delete the generated file once it's processed.
    br
    | The process might take a few minutes.


@@ 404
p Not found


