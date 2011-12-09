(function() {
  var APP;
  this.APP = APP = {};
  APP.Search = (function() {
    var currentSize, imageSearch, imageTemplate, lastSearch, obj, searchSizes;
    imageSearch = null;
    imageTemplate = null;
    searchSizes = null;
    currentSize = null;
    lastSearch = null;
    obj = {
      init: function() {
        searchSizes = [["icon"], ["small"], ["medium"]];
        imageSearch = new google.search.ImageSearch();
        imageSearch.setSearchCompleteCallback(this, this.handleResults, null);
        imageSearch.setResultSetSize(6);
        return imageTemplate = Handlebars.compile($('#image-template').html());
      },
      handleResults: function() {
        var index, inst;
        $('#image-results .images').append(imageTemplate(imageSearch.results));
        inst = this;
        $('.image-result a').draggable({
          helper: function() {
            var img, srcImage;
            srcImage = $('img', this);
            img = srcImage.clone();
            img.attr('src', srcImage.attr('data-src'));
            img.data('thumb-src', srcImage.attr('src'));
            inst.dropTarget = img.get(0);
            return inst.dropTarget;
          },
          opacity: .6
        });
        google.search.Search.getBranding('google-branding');
        index = searchSizes.indexOf(currentSize);
        if (index > -1 && index < searchSizes.length - 1) {
          currentSize = searchSizes[index + 1];
          return this.executeSearch();
        }
      },
      executeSearch: function() {
        imageSearch.setRestriction(google.search.ImageSearch.RESTRICT_IMAGESIZE, currentSize);
        return imageSearch.execute(lastSearch);
      },
      search: function(q) {
        currentSize = searchSizes[0];
        lastSearch = q;
        $('#image-results .images').empty();
        return this.executeSearch();
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
            var canvasPos, dropTarget, imgPos, src, x, y;
            imgPos = ui.position;
            canvasPos = $('#canvas').position();
            x = imgPos.left - canvasPos.left;
            y = imgPos.top - canvasPos.top;
            dropTarget = APP.Search.dropTarget;
            src = $(dropTarget).attr('src');
            return inst.addImage(dropTarget, x, y);
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
        this.updateUI();
        return this.redraw();
      },
      updateUI: function() {
        var image, urls, _i, _len;
        urls = [];
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          image = images[_i];
          urls.push(image.sourceUrl);
        }
        return $('#image-sources').html(urls.join(', '));
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
      },
      rearrange: function(arrangement) {
        this.arrangements[arrangement]();
        return this.redraw();
      },
      resize: function(size) {
        var image, _i, _len;
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          image = images[_i];
          image.scaleTo(size);
        }
        return this.redraw();
      },
      arrangements: {
        _linear: function(primaryName, primaryAxis, secondaryName, secondaryAxis) {
          var canvasPrimary, canvasSecondary, d, image, imagesTotal, padding, paddings, _i, _j, _len, _len2, _results;
          canvasPrimary = canvas[primaryName];
          canvasSecondary = canvas[secondaryName];
          imagesTotal = 0;
          for (_i = 0, _len = images.length; _i < _len; _i++) {
            image = images[_i];
            imagesTotal += image[primaryName];
          }
          padding = imagesTotal * .2;
          paddings = images.length - 1;
          if (padding + imagesTotal > canvasPrimary) {
            padding = Math.min((canvasPrimary - imagesTotal) / paddings, 5);
          }
          imagesTotal += padding * paddings;
          d = (canvasPrimary - imagesTotal) / 2;
          _results = [];
          for (_j = 0, _len2 = images.length; _j < _len2; _j++) {
            image = images[_j];
            image[primaryAxis] = d;
            image[secondaryAxis] = (canvasSecondary - image[secondaryName]) / 2;
            _results.push(d += image[primaryName] + padding);
          }
          return _results;
        },
        horizontal: function() {
          return this._linear('width', 'x', 'height', 'y');
        },
        vertical: function() {
          return this._linear('height', 'y', 'width', 'x');
        }
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
      this.src = this.sourceUrl = src;
      this.thumbSrc = thumbSrc;
      this.width = this.origWidth = width;
      this.height = this.origHeight = height;
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
        ctx.save();
        if (this.scale !== 1) {
          ctx.scale(this.scale, this.scale);
        }
        if (this.loaded) {
          ctx.drawImage(this.img, this.x / this.scale, this.y / this.scale);
        }
        return ctx.restore();
      },
      scaleTo: function(size) {
        var scale;
        if (size >= this.origWidth && size >= this.origHeight) {
          scale = 1;
        } else if (this.origWidth > this.origHeight) {
          scale = size / this.origWidth;
        } else {
          scale = size / this.origHeight;
        }
        this.scale = scale;
        this.width = this.origWidth * scale;
        return this.height = this.origHeight * scale;
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
    $('.topbar a.about').click(function() {
      $('#about').slideToggle();
      return false;
    });
    $('#about .close').click(function() {
      $('#about').slideToggle();
      return false;
    });
    $('#arrangements').delegate('button', 'click', function() {
      return APP.Canvas.rearrange($(this).data('arrangement'));
    });
    return $('#resize').click(function() {
      return APP.Canvas.resize($('#size').val());
    });
  });
}).call(this);
