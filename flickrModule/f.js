function init_flickr_iframe (mode, height) {
  rbf_selectQuery('SELECT flickr_api_key, flickr_s_s, flickr_a_t, flickr_a_s, flickr_u_id FROM $SETTINGS', 1, function (vals) {
    var iframeWidth = '900px',
        api_key = vals[0][0],
        s_s = vals[0][1],
        at = vals[0][2],
        as = vals[0][3],
        uid = vals[0][4],
        applicationId = getURLParameter('id'),
        visitorId = current_visitor.id,
        iframe = $("<iframe height='" + height + "'></iframe>"),
        container = $("<div class='flex-photo widescreen'></div>"),
        // url = ["https://sinatra-blahaas.rhcloud.com",
        // Replace the first part with the pow info.
        url = ["https://v.gdg.do",
              api_key,
              s_s,
              at,
              as,
              uid,
              visitorId,
              applicationId,
              mode];

    url = url.join('/');
    container.appendTo('[name="Photo Content Target"]');
    iframe.prop('src', url).appendTo('.flex-photo');
  });
}

$('document').ready(function () {
  var g = getURLParameter('g');
  if (g == portal_pages.photo_edit_page) {
    init_flickr_iframe('e', '2000px');
  }
  else if (g == portal_pages.photo_review_page) {
    init_flickr_iframe('v', '500px');
  }
  else if (g == portal_pages.photo_view_page) {
    init_flickr_iframe('v', '500px');
  }
});
