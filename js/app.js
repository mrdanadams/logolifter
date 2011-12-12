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
            var img, largeImg, srcImage;
            srcImage = $('img', this);
            img = srcImage.clone();
            img.attr('width', img.data('width'));
            img.attr('height', img.data('height'));
            img.data('thumb-src', srcImage.attr('src'));
            largeImg = new Image();
            largeImg.onload = function() {
              return img.attr('src', largeImg.src);
            };
            largeImg.src = srcImage.data('src');
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
    var canvas, cropBorder, cropEnable, ctx, dragImg, dragX, dragY, imageSize, images, inst, obj;
    ctx = null;
    canvas = null;
    images = [];
    dragImg = null;
    dragX = null;
    dragY = null;
    inst = null;
    cropEnable = true;
    cropBorder = 0;
    imageSize = null;
    obj = {
      init: function() {
        var jc, name, _i, _len, _ref;
        canvas = $('#canvas').get(0);
        ctx = canvas.getContext('2d');
        inst = this;
        jc = $('#canvas');
        _ref = ['mousemove', 'mouseup', 'mousedown', 'dblclick'];
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
      _getOffset: function(event) {
        var offset, x, y;
        x = null;
        y = null;
        if (event.offsetX || event.offsetY) {
          x = event.offsetX;
          y = event.offsetY;
        } else {
          offset = $(event.target).offset();
          x = event.pageX - offset.left;
          y = event.pageY - offset.top;
        }
        return {
          x: x,
          y: y
        };
      },
      _getHitImage: function(event) {
        var img, offset, x, y, _i, _len;
        offset = inst._getOffset(event);
        x = offset.x;
        y = offset.y;
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          img = images[_i];
          if (x >= img.x && y >= img.y && x <= img.x + img.width && y <= img.y + img.height) {
            return img;
          }
        }
        return null;
      },
      dblclick: function(event) {
        var img, index;
        img = inst._getHitImage(event);
        if (!img) {
          return;
        }
        index = images.indexOf(img);
        images.splice(index, 1);
        inst.updateUI();
        return inst.redraw();
      },
      mousedown: function(event) {
        var img, offset;
        img = inst._getHitImage(event);
        if (img) {
          dragImg = img;
          offset = inst._getOffset(event);
          dragX = offset.x - img.x;
          return dragY = offset.y - img.y;
        }
      },
      mousemove: function(event) {
        var offset;
        if (dragImg === null) {
          return;
        }
        offset = inst._getOffset(event);
        dragImg.x = offset.x - dragX;
        dragImg.y = offset.y - dragY;
        return inst.redraw();
      },
      mouseup: function() {
        dragImg = null;
        return inst.redraw();
      },
      addImage: function(dropped, x, y) {
        var img;
        dropped = $(dropped);
        img = new APP.Canvas.Img(dropped.attr('src'), dropped.data('src'), dropped.data('thumb-src'), dropped.data('width'), dropped.data('height'), x, y, ctx);
        if (imageSize) {
          img.scaleTo(imageSize);
        }
        images.push(img);
        this.updateUI();
        this.redraw();
        return img.sanitize(ctx);
      },
      resize: function(size) {
        var image, _i, _len;
        imageSize = size ? size : canvas.width;
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          image = images[_i];
          image.scaleTo(imageSize);
        }
        return this.redraw();
      },
      crop: function(border) {
        cropBorder = border ? Math.max(parseInt(border), 0) : 0;
        return this.redraw();
      },
      updateUI: function() {
        var image, urls, _i, _len;
        urls = [];
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          image = images[_i];
          urls.push(image.sourceUrl);
        }
        $('#image-sources').html(urls.join(', '));
        return $('#download').attr('disabled', (images.length > 0 ? null : 'disabled'));
      },
      download: function() {
        var dirty, image, proceed, _i, _len;
        dirty = [];
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          image = images[_i];
          if (image.dirty) {
            dirty.push(image);
          }
        }
        proceed = function() {
          var canvas2, img;
          if (dirty.length > 0) {
            img = dirty.shift();
            return img.sanitize(null, proceed);
          } else {
            canvas2 = inst._drawCanvas();
            return Canvas2Image.saveAsPNG(canvas2);
          }
        };
        return proceed();
      },
      redraw: function() {
        var info;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        if (images.length === 0) {
          return;
        }
        info = this._calculateCanvas();
        ctx.fillStyle = "#333";
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = "#fff";
        ctx.fillRect(info.xMin, info.yMin, info.width, info.height);
        return this._redraw(ctx, canvas);
      },
      _calculateCanvas: function() {
        var b, height, image, width, xMax, xMin, yMax, yMin, _i, _len;
        xMin = canvas.width;
        xMax = 0;
        yMin = canvas.height;
        yMax = 0;
        for (_i = 0, _len = images.length; _i < _len; _i++) {
          image = images[_i];
          xMin = Math.min(xMin, image.x);
          xMax = Math.max(xMax, image.x + image.width);
          yMin = Math.min(yMin, image.y);
          yMax = Math.max(yMax, image.y + image.height);
        }
        b = cropEnable ? cropBorder : 0;
        xMin = xMin - b;
        xMax = xMax + b;
        yMin = yMin - b;
        yMax = yMax + b;
        width = xMax - xMin;
        height = yMax - yMin;
        return {
          width: width,
          height: height,
          xMin: xMin,
          xMax: xMax,
          yMin: yMin,
          yMax: yMax,
          border: b
        };
      },
      _drawCanvas: function() {
        var canvas2, ctx2, info;
        info = this._calculateCanvas();
        canvas2 = $(['<canvas width="', info.width, '" height="', info.height, '"></canvas>'].join('')).get(0);
        ctx2 = canvas2.getContext('2d');
        ctx2.clearRect(0, 0, canvas2.width, canvas2.height);
        ctx2.fillStyle = "#fff";
        ctx2.fillRect(0, 0, info.width, info.height);
        ctx2.save();
        ctx2.translate(-info.xMin, -info.yMin);
        this._redraw(ctx2, canvas2);
        ctx2.restore();
        return canvas2;
      },
      _redraw: function(ctx, canvas) {
        var image, _i, _len, _results;
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
          padding = imagesTotal * .1;
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
    cls = function(src, sourceUrl, thumbSrc, width, height, x, y, ctx) {
      this.safe = false;
      this.sourceUrl = sourceUrl;
      this.thumbSrc = thumbSrc;
      this.dirty = true;
      this.width = this.origWidth = width;
      this.height = this.origHeight = height;
      this.x = x;
      this.y = y;
      this.scale = 1;
      this._setSrc(src, ctx);
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
      },
      sanitize: function(ctx, callback) {
        var inst, src;
        callback = callback || function() {};
        if (!this.dirty) {
          callback();
          return;
        }
        inst = this;
        src = this.sourceUrl;
        return $.getImageData({
          url: src,
          success: function(image) {
            inst._setSrc(image.src, ctx);
            inst.dirty = false;
            return callback();
          },
          error: function(xhr, text_status) {
            return callback();
          }
        });
      },
      _setSrc: function(src, ctx) {
        var img, inst;
        this.src = src;
        this.img = img = new Image();
        this.loaded = false;
        inst = this;
        img.onload = function() {
          inst.loaded = true;
          if (ctx) {
            return inst.draw(ctx);
          }
        };
        return img.src = src;
      }
    };
    return cls;
  })();
  $(function() {
    var updateCrop;
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
    $('#size').on("keyup", function() {
      return APP.Canvas.resize($(this).val());
    });
    updateCrop = function() {
      return APP.Canvas.crop($('#crop-size').val());
    };
    $('#crop-size').on("keyup", updateCrop);
    return updateCrop();
  });
}).call(this);
