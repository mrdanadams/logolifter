(function() {
  var APP;
  this.APP = APP = {};
  APP.Search = (function() {
    var imageSearch, imageTemplate, obj;
    imageSearch = null;
    imageTemplate = null;
    obj = {
      init: function() {
        imageSearch = new google.search.ImageSearch();
        imageSearch.setSearchCompleteCallback(this, this.handleResults, null);
        imageSearch.setResultSetSize(6);
        return imageTemplate = Handlebars.compile($('#image-template').html());
      },
      handleResults: function() {
        $('#image-results .images').empty().append(imageTemplate(imageSearch.results));
        $('.image-result a').draggable({
          helper: function() {
            var img, srcImage;
            srcImage = $('img', this);
            img = srcImage.clone();
            img.attr('src', srcImage.attr('data-src'));
            img.data('thumb-src', srcImage.attr('src'));
            return img.get(0);
          },
          opacity: .6
        });
        return google.search.Search.getBranding('google-branding');
      },
      search: function(q) {
        return imageSearch.execute(q);
      }
    };
    google.load('search', '1');
    google.setOnLoadCallback(function() {
      return obj.init();
    });
    return obj;
  })();
  APP.Canvas = (function() {
    var canvas, ctx, dragImg, dragX, dragY, images, inst, obj;
    ctx = null;
    canvas = null;
    images = [];
    dragImg = null;
    dragX = null;
    dragY = null;
    inst = null;
    obj = {
      init: function() {
        var jc, name, _i, _len, _ref;
        canvas = $('#canvas').get(0);
        ctx = canvas.getContext('2d');
        inst = this;
        jc = $('#canvas');
        _ref = ['mousemove', 'mouseup', 'mousedown'];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          name = _ref[_i];
          jc.bind(name, inst[name]);
        }
        return jc.droppable({
          accept: '.image-result a',
          activeClass: 'drop-highlight',
          drop: function(event, ui) {
            var canvasPos, imgPos, src, x, y;
            imgPos = ui.position;
            canvasPos = $('#canvas').position();
            x = imgPos.left - canvasPos.left;
            y = imgPos.top - canvasPos.top;
            src = $(event.target).attr('src');
            return inst.addImage(event.target, x, y);
          }
        });
      },
      mousedown: function(event) {
        var img, x, y, _i, _len, _results;
        x = event.offsetX;
        y = event.offsetY;
        _results = [];
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          img = images[_i];
          _results.push(x >= img.x && y >= img.y && x <= img.x + img.width && y <= img.y + img.height ? (dragImg = img, dragX = x - img.x, dragY = y - img.y) : void 0);
        }
        return _results;
      },
      mousemove: function(event) {
        if (dragImg === null) {
          return;
        }
        dragImg.x = event.offsetX - dragX;
        dragImg.y = event.offsetY - dragY;
        return inst.redraw();
      },
      mouseup: function() {
        dragImg = null;
        return inst.redraw();
      },
      addImage: function(dropped, x, y) {
        var img;
        dropped = $(dropped);
        img = new APP.Canvas.Img(dropped.attr('src'), dropped.data('thumb-src'), dropped.data('width'), dropped.data('height'), x, y, ctx);
        images.unshift(img);
        return this.redraw();
      },
      download: function() {
        return Canvas2Image.saveAsPNG($('#canvas').get(0));
      },
      redraw: function() {
        var image, _i, _len, _results;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        _results = [];
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          image = images[_i];
          _results.push(image.draw(ctx));
        }
        return _results;
      }
    };
    $(function() {
      return obj.init();
    });
    return obj;
  })();
  APP.Canvas.Img = (function() {
    var cls;
    cls = function(src, thumbSrc, width, height, x, y, ctx) {
      var img, inst;
      this.safe = false;
      this.src = src;
      this.thumbSrc = thumbSrc;
      this.width = width;
      this.height = height;
      this.x = x;
      this.y = y;
      this.scale = 1;
      this.img = img = new Image();
      this.loaded = false;
      inst = this;
      img.onload = function() {
        inst.loaded = true;
        return inst.draw(ctx);
      };
      img.src = src;
      return this;
    };
    cls.prototype = {
      draw: function(ctx) {
        if (this.loaded) {
          return ctx.drawImage(this.img, this.x, this.y);
        }
      }
    };
    return cls;
  })();
  $(function() {
    $('#search-form form').submit(function(event) {
      return false;
    });
    $('#q').on('keydown', function(event) {
      if (event.keyCode === 13) {
        return APP.Search.search($(this).val());
      }
    });
    $('#download').click(function() {
      return APP.Canvas.download();
    });
    return $('.topbar a.about').click(function() {
      $('#about').slideDown();
      return false;
    });
  });
}).call(this);
