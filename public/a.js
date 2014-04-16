$(function() {
  $('a.show').click(function() {
    if ($(this).hasClass('upload')) $('#upload').fadeIn(100)
    if ($(this).hasClass('about')) $('#about').fadeIn(100)
  });


  var resize = function() {
    var bg = $('#bg');
    var img = $('img', bg);
    if (img.length) {
      var sw = $(window).width();
      var sh = $(window).height();
      var iw = img.width();
      var ih = img.height();
      if (ih * (sw / iw) > sh) {
        img.width(sw);
        img.height(ih * sw / iw);
        bg.css({'left': '0px', 'top': ((sh - img.height()) / 2) + 'px' });
      } else {
        img.width(iw * sh / ih);
        img.height(sh);
        bg.css({'left': ((sw - img.width()) / 2) + 'px', 'top': '0px' });
      }
    } else {
      bg.height($(window).height());
    }
  };
  $(window).resize(resize);
  resize();


  var show = function() {
    var bg = $('#bg');
    var img = $('<img />');
    var delay = 1000;
    var disapear = 5000;
    img.load(function() {
      bg.append(img);
      resize();
      img.fadeIn(delay);
      $('h1').animate({'color': '#FFF'}, delay, function() {
        var me = this;
        setTimeout(function() { $(me).hide() }, disapear);
      });
      bg.removeClass('loading');
    });
    img.attr('src', bg.data('src'));
  };
  show();
});
