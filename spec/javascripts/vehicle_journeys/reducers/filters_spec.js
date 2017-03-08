var statusReducer = require('es6_browserified/vehicle_journeys/reducers/filters')

let state = {}

describe('filters reducer', () => {
  const cleanInterval = {
    start:{
      hour: '00',
      minute: '00'
    },
    end:{
      hour: '23',
      minute: '59'
    }
  }
  beforeEach(() => {
    state = {
    toggleArrivals: false,
    query: {
      interval: {
        start:{
          hour: '11',
          minute: '11'
        },
        end:{
          hour: '22',
          minute: '22'
        }
      },
      journeyPattern: {},
      timetable: {},
      withoutSchedule: false,
    },
    queryString: ''
    }
  })

  it('should return the initial state', () => {
    expect(
      statusReducer(undefined, {})
    ).toEqual({})
  })

  it('should handle TOGGLE_ARRIVALS', () => {
    expect(
      statusReducer(state, {
        type: 'TOGGLE_ARRIVALS'
      })
    ).toEqual(Object.assign({}, state, {toggleArrivals: true}))
  })

  it('should handle RESET_FILTERS', () => {
    let cleanQuery = JSON.parse(JSON.stringify(state.query))
    cleanQuery.interval = cleanInterval
    expect(
      statusReducer(state, {
        type: 'RESET_FILTERS'
      })
    ).toEqual(Object.assign({}, state, {query: cleanQuery}))
  })

  it('should handle TOGGLE_WITHOUT_SCHEDULE', () => {
    let rslt = JSON.parse(JSON.stringify(state.query))
    rslt.withoutSchedule = true
    expect(
      statusReducer(state, {
        type: 'TOGGLE_WITHOUT_SCHEDULE'
      })
    ).toEqual(Object.assign({}, state, {query: rslt}))
  })

  it('should handle UPDATE_START_TIME_FILTER', () => {
    let val = 12
    let unit = 'minute'
    let rslt = JSON.parse(JSON.stringify(state.query))
    rslt.interval.start.minute = String(val)
    expect(
      statusReducer(state, {
        type: 'UPDATE_START_TIME_FILTER',
        val,
        unit
      })
    ).toEqual(Object.assign({}, state, {query: rslt}))
  })

  it('should handle UPDATE_START_TIME_FILTER and not make any update', () => {
    let val = 23
    let unit = 'hour'
    expect(
      statusReducer(state, {
        type: 'UPDATE_START_TIME_FILTER',
        val,
        unit
      })
    ).toEqual(state)
  })

  it('should handle UPDATE_END_TIME_FILTER', () => {
    let val = 12
    let unit = 'minute'
    let rslt = JSON.parse(JSON.stringify(state.query))
    rslt.interval.end.minute = String(val)
    expect(
      statusReducer(state, {
        type: 'UPDATE_END_TIME_FILTER',
        val,
        unit
      })
    ).toEqual(Object.assign({}, state, {query: rslt}))
  })

  it('should handle UPDATE_END_TIME_FILTER and not make any update', () => {
    let val = 1
    let unit = 'hour'
    expect(
      statusReducer(state, {
        type: 'UPDATE_END_TIME_FILTER',
        val,
        unit
      })
    ).toEqual(state)
  })

  it('should handle SELECT_TT_FILTER', () => {
    let newTimetable = {timetable : {id: 1}}
    let newQuery = Object.assign({}, state.query, newTimetable)
    expect(
      statusReducer(state, {
        type: 'SELECT_TT_FILTER',
        selectedItem: {id: 1}
      })
    ).toEqual(Object.assign({}, state, {query: newQuery}))
  })

  it('should handle SELECT_JP_FILTER', () => {
    let newJourneyPattern = {journeyPattern : {id: 1}}
    let newQuery = Object.assign({}, state.query, newJourneyPattern)
    expect(
      statusReducer(state, {
        type: 'SELECT_JP_FILTER',
        selectedItem: {id: 1}
      })
    ).toEqual(Object.assign({}, state, {query: newQuery}))
  })
})
