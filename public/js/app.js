$('document').ready(function() {

  // show btn toolbar on hover
  // $('.media-list li, .slickel').hover(function () {
  //   $(this).find('#btnContainer').toggle();
  // });

  //upload form stuff
  // $('#upload-form').on('submit', function(e) {
  //   e.preventDefault();
  //   $('[type=submit]').prop('disabled',true).html('Uploading, Please Wait... <i class="fa fa-spin fa-spinner">');
  //   // $('#uploadModal').modal('hide');
  //   $(this).off('submit').submit();
  // });

  //hide flash message after 5 seconds
  setTimeout(function () {
    $('.alert-info').hide();
  }, 5000);


  //loop through thumbnails and make an initial assessment of selectedness
  $('.thumbnail').each(function (i, val) {
    if ($(val).hasClass('selected')) {
      $(val).find('.icon').show();
    }
    else {
      $(val).find('.icon').hide();
    }
  });

  //Photo thumbnail click handler
  $('.thumbnail').on('click', function () {
    var idStr = "",
        detachStr = "",
        _this = $(this);

    _this.toggleClass('selected');
    if (_this.hasClass('selected')) {
      _this.find('.icon').show();
    }
    else {
      _this.find('.icon').hide();
    }

    $('.thumbnail').each(function (i, val) {
      if ($(this).hasClass('selected')) {
        idStr += $(this).attr('id') + ',';
      }
      else {
        detachStr += $(this).attr('id') + ',';
      }
    });

    if (detachStr == "") {
      detachStr = 0;
    }

    if (idStr == "") {
      idStr = 0;
    }

    $('#attachPhotoBtn').attr('href', '/attach/' + idStr + "/" + detachStr);
  });

  // So, the photo modal is blocking the choose button as soon as the page is loaded.
  // If we hide it using the .hide() function it is no problem.
  $("#photoListModal").hide();

  // $('#attachVidBtn').on('click', function () {
  //   var idArray = "";
  //
  //   $(this).attr('disabled',true).html('Attaching... <i class="fa fa-spin fa-spinner">');
  //
  //   $('.thumbnail').each(function (i, val) {
  //     idArray += $(this).attr('id') + ',';
  //   });
  //
  //   // $.get('/attach/' + idArray, function (data) {
  //   //   $('#vidListModal').modal('hide');
  //   //   $('#attachVidBtn').attr('disabled',false).html('Attach');
  //   // });
  // });

  $('#slickcontainer').slick({
    dots: true,
    infinite: false,
    speed: 300,
    slidesToShow: 3,
    // touchMove: true,
    lazyLoad: 'ondemand',
    slidesToScroll: 1,
      responsive: [
    {
      breakpoint: 1024,
      settings: {
        slidesToShow: 3,
        slidesToScroll: 1,
        infinite: false,
        arrows: false,
        dots: true
      }
    },
    {
      breakpoint: 600,
      settings: {
        slidesToShow: 2,
        slidesToScroll: 2,
        infinite: false,
        arrows: false,
        dots: true
      }
    },
    {
      breakpoint: 480,
      settings: {
        slidesToShow: 1,
        slidesToScroll: 1,
        infinite: false,
        arrows: false,
        dots: true
      }
    }
  ]
});

  // File sizes must be greater than 15 KB
  $('#file').bind('change', function() {
    if((this.files[0].size) / 1024 < 15) {

      // Build string and prepend it to the body tag.
      var htmlString = '<p id="myError" style>Error: ​File size must be greater than 15 KB.​</p>';
      $("body").prepend(htmlString);
      $("#myError").addClass("​alert alert-danger");

      //hide flash message after 5 seconds
      setTimeout(function () {
        $('.alert-danger').hide();
      }, 5000);

      $("[type='submit']").attr("disabled", "true");
    } else {
      $("[type='submit']").removeAttr("disabled");
    }
  });

});
