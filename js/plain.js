function initCalendar($calendar) {
  var apiURL = $calendar.data('url');
  $.get(apiURL, function(data) {
    var events = _.map(data.hearings, _formatHearingData);

    var calendar = $calendar.calendar({
      tmpl_path: '/bootstrap-calendar/tmpls/',
      events_source: events,
      all_events: events,
      onAfterViewLoad: function(view) {
        $('h3.calendar-title').text(this.getTitle());
      },
      views: {
        day: { enable: 0 }
      }
    });

    $('button[data-calendar-nav]').each(function() {
      var $this = $(this);
      $this.click(function() {
        calendar.navigate($this.data('calendar-nav'));
        _afterCalendarRender();
      });
    });

    var $selectFilter = $("input[name='dashboard[filter-hearings][]']");
    _filterByHearings($selectFilter, calendar);
    _afterCalendarRender();
  });
}

function _filterByHearings($select, calendar) {
  var $el = $select;

  $el.on('change', function() {
    var ids = $el.val();

    calendar.options.events_source = _.select(
      calendar.options.all_events,
      function(ev) {
        if (ids.indexOf('all') > -1 || _.size(ids) === 0) {
          return true;
        }
        if (ids.indexOf('only_house') > -1 && ev.committee_type === 'house') {
          return true;
        }
        if (ids.indexOf('only_senate') > -1 && ev.committee_type === 'senate') {
          return true;
        }
        if (ids.indexOf(ev.committee_id) > -1) {
          return true;
        }
        return false;
      }
    );
    calendar.view();
    _afterCalendarRender();
  });
}
////////////////////////////////////////////////////////////////////////////
