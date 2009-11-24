jQuery(document).ready(function($){
  
  $('input#checkout_use_billing').click(function() {
    if ($(this).attr('checked') == true) {
      $('div#shipping .inner').hide();
      $('div#shipping .inner input').attr('disabled', 'disabled');
    } else {
      $('div#shipping .inner').show();
      $('div#shipping .inner input').removeAttr('disabled', 'disabled');
    }
  });
  
});