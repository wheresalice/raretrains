var params = {};
window.location.search.replace(/[?&]+([^=&]+)=([^&]*)/gi, function (str, key, value) {
    params[key] = value;
});
$('.serviceslink').each(function (i) {
    if (typeof(params['date']) != 'undefined') {
        this.href = this.href + '?date=' + params['date'];
    }
});

$('#station_button').click(function () {
    var station = $('#station')[0].value;
    var date = $('#date')[0].value;
    var datestr = '';
    if (date != '') {
        datestr = '?date=' + date;
    }
    if ($('#unique')[0].checked == true) {
        location.href = '/' + station + '/unique' + datestr;
    } else {
        location.href = '/' + station + datestr;
    }
});

$('#station').keyup(function () {
    this.value = this.value.toUpperCase();
});

$(document).on('click', '.panel-heading span.clickable', function(e){
    var $this = $(this);
    if(!$this.hasClass('panel-collapsed')) {
        $this.parents('.panel').find('.panel-body').slideUp();
        $this.addClass('panel-collapsed');
        $this.find('i').removeClass('glyphicon-chevron-up').addClass('glyphicon-chevron-down');
    } else {
        $this.parents('.panel').find('.panel-body').slideDown();
        $this.removeClass('panel-collapsed');
        $this.find('i').removeClass('glyphicon-chevron-down').addClass('glyphicon-chevron-up');
    }
});

$(function () {
    $('[data-toggle="tooltip"]').tooltip()
});