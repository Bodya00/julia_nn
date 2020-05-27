var interval_reference = null

function check_prediction_progress(){
  $.ajax( '/check_prediction_progress', {
    type: 'GET',
    success: function( resp ) {
      clearInterval(interval_reference);
      window.location.replace("/view_predictions");
    }
  }
)};

$(document).ready(function(){
    interval_reference = setInterval(check_prediction_progress, 2000);
});
