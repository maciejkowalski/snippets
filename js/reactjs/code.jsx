/////////////////////////////////////////////////////////////////////
// Components responsible for Calendar. React + Redux
/////////////////////////////////////////////////////////////////////

import React from 'react';
import classNames from 'classnames';
import chamberInSession from '../chamber-in-session';

export default function DateCellWrapper(props) {
  const time = props.value;
  const houseSession = chamberInSession('house', time);
  const senateSession = chamberInSession('senate', time);

  const houseClasses = classNames({
    'house-day-in-session': houseSession,
  }, 'day-in-session');
  const senateClasses = classNames({
    'senate-day-in-session': senateSession,
  }, 'day-in-session');

  const childrenProps = props.children.props;

  return (
    <div className={childrenProps.className} style={childrenProps.style}>
      <div className={senateClasses}>
        {(senateSession ? 'S' : '')}
      </div>
      <div className={houseClasses}>
        {(houseClasses ? 'H' : '')}
      </div>
    </div>
  );
}

DateCellWrapper.propTypes = {
  value: React.PropTypes.instanceOf(Date).isRequired,
  children: React.PropTypes.object.isRequired,
};

/////////////////////////////////////////////////////////////////////
import React from 'react';
import moment from 'moment';
import BigCalendar from 'react-big-calendar';
import Event from './event.jsx';
import EventAgenda from './event-agenda.jsx';
import DateCellWrapper from './date-cell-wrapper.jsx';
import EventModal from './event_modal.jsx';

BigCalendar.setLocalizer(
  BigCalendar.momentLocalizer(moment)
);

export default class Container extends React.Component {
  static defaultProps = {
    hearings: [],
    committees: [],
  };

  static propTypes = {
    fetchHearings: React.PropTypes.func.isRequired,
    hearings: React.PropTypes.array,
    committees: React.PropTypes.array,
  };

  state = {
    fieldModalOpen: false,
    modalEvent: {},
    view: 'agenda',
    date: new Date(),
  };

  componentDidMount() {
    this.props.fetchHearings(this.getRequestHash());
    // remote 'Today' button from tollbar - there is no 'clean' way to do this
    $('.rbc-toolbar .rbc-btn-group button:first').remove();
  }

  onCalendarDateChange = (date) => {
    this.setState({ date }, () => { this.props.fetchHearings(this.getRequestHash()); });
  }

  onCalendarViewChange = (view) => {
    this.setState({ view }, () => { this.props.fetchHearings(this.getRequestHash()); });
  }

  getRequestHash = () => ({
    month: this.state.date.getMonth() + 1,
    year: this.state.date.getUTCFullYear(),
    view: this.state.view,
  })

  handleOpenFieldModal = (event) => {
    this.setState({ fieldModalOpen: true, modalEvent: event });
  }

  handleCloseFieldModal = () => {
    this.setState({ fieldModalOpen: false });
  }

  filterByCommittees() {
    if (!this.props.committees || this.props.committees.length === 0) {
      return this.props.hearings;
    }

    const committees = this.props.committees;
    const selected = this.props.hearings.filter((hearing) => {
      if (committees.indexOf('all') > -1) {
        return true;
      }
      if (committees.indexOf('only_house') > -1 && hearing.committee_type === 'house') {
        return true;
      }
      if (committees.indexOf('only_senate') > -1 && hearing.committee_type === 'senate') {
        return true;
      }
      if (committees.indexOf(hearing.committee_id) > -1) {
        return true;
      }
      return false;
    });
    return selected;
  }

  render() {
    const views = ['agenda', 'month'];
    const defaultView = 'agenda';
    const eventPropGetter = event => ({
      className: event.html_class,
    });
    const messages = {
      agenda: 'List',
      today: 'Today',
      previous: 'Previous',
      next: 'Next',
      month: 'Calendar',
    };

    return (
      <div>
        <div>
          <b>Key:</b>
        </div>
        <span className="caption-span">
          <div className="house-button rbc-event caption-event">
            <div className="rbc-event-content">
              <span>
                <strong>House Hearing</strong>
              </span>
            </div>
          </div>
          <div className="senate-button rbc-event caption-event">
            <div className="rbc-event-content">
              <span>
                <strong>Senate Hearing</strong>
              </span>
            </div>
          </div>
          <div className="rbc-event caption-event">
            <div className="rbc-event-content">
              <span>
                <strong>Joint Hearing</strong>
              </span>
            </div>
          </div>
        </span>

        <BigCalendar
          popup
          defaultView={defaultView}
          views={views}
          events={this.filterByCommittees()}
          components={{
            event: Event,
            dateCellWrapper: DateCellWrapper,
            agenda: {
              event: EventAgenda,
            },
          }}
          messages={messages}
          eventPropGetter={eventPropGetter}
          onSelectEvent={this.handleOpenFieldModal}
          onNavigate={this.onCalendarDateChange}
          onView={this.onCalendarViewChange}
        />
        <EventModal
          event={this.state.modalEvent}
          open={this.state.fieldModalOpen}
          onClose={this.handleCloseFieldModal}
        />
      </div>
    );
  }
}

/////////////////////////////////////////////////////////////////////
import React from 'react';
import { bindActionCreators } from 'redux';
import { Provider, connect } from 'react-redux';
import store from 'redux/store';
import * as Actions from 'redux/under-the-dome-calendar';
import Container from './components/container.jsx';

function mapStateToProps(state) {
  return { ...state.underTheDomeCalendar };
}

function mapDispatchToProps(dispatch) {
  return bindActionCreators(Actions, dispatch);
}

const ConnectedContainer = connect(mapStateToProps, mapDispatchToProps)(Container);

export default function () {
  return (
    <Provider store={store}>
      <ConnectedContainer />
    </Provider>
  );
}

