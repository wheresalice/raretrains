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