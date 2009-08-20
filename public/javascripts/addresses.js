var show_hide_shipping_address = function() {
  if($("#ship_address_use_bill_address")[0].checked){
    $("#ship_address").hide();
  } else {
    $("#ship_address").show();
  };
}

var update_states = function(country_select) {
  var states  = state_mapper[country_select.val()];
  var wrapper_div = country_select.parents('div.inner');

  if (states) {
    // show and enable select
    wrapper_div.find('select.state').attr('disabled', false).show()
    // hide and disable input
    wrapper_div.find('input.state_name').attr('disabled', true).hide()
    // recreate state selection list
    replacement = wrapper_div.find('select.state');
    replacement.children().remove().end()

    var states_with_blank = [["",""]].concat(states);
    $.each(states_with_blank, function(pos,id_nm) {
      var opt = $(document.createElement('option'))
      .attr('value', id_nm[0])
      .html(id_nm[1]);
      replacement.append(opt);
    });
  } else {
    // hide and disable select
    wrapper_div.find('select.state').attr('disabled', true).hide()
    // show and enable input
    wrapper_div.find('input.state_name').attr('disabled', false).show()
  }
}

$(document).ready(function () {
  $("#ship_address_use_bill_address").click(show_hide_shipping_address);
  show_hide_shipping_address();

  $('.inner .country').change(function(ev){
    update_states($(ev.target));
  });

  $('.inner .country').each(function(i, el) {
    update_states($(el));
  });
});