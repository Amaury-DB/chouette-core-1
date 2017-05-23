var actions = require('../actions')
var connect = require('react-redux').connect
var StopPointList = require('../components/StopPointList')

const mapStateToProps = (state) => {
  return {
    stopPoints: state.stopPoints
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onDeleteClick: (index) =>{
      dispatch(actions.deleteStop(index))
      dispatch(actions.closeMaps())
    },
    onMoveUpClick: (index) =>{
      dispatch(actions.moveStopUp(index))
      dispatch(actions.closeMaps())
    },
    onMoveDownClick: (index) =>{
      dispatch(actions.moveStopDown(index))
      dispatch(actions.closeMaps())
    },
    onChange: (index, text) =>{
      dispatch(actions.updateInputValue(index, text))
      dispatch(actions.closeMaps())
      dispatch(actions.toggleEdit(index))
    },
    onSelectChange: (e, index) =>{
      dispatch(actions.updateSelectValue(e, index))
      dispatch(actions.closeMaps())
    },
    onToggleMap: (index) =>{
      dispatch(actions.toggleMap(index))
    },
    onToggleEdit: (index) =>{
      dispatch(actions.toggleEdit(index))
    },
    onSelectMarker: (index, data) =>{
      dispatch(actions.selectMarker(index, data))
    },
    onUnselectMarker: (index) =>{
      dispatch(actions.unselectMarker(index))
    },
    onUpdateViaOlMap: (index, data) =>{
      dispatch(actions.updateInputValue(index, data))
      dispatch(actions.toggleMap(index))
    }
  }
}

const VisibleStopPoints = connect(
  mapStateToProps,
  mapDispatchToProps
)(StopPointList)

module.exports = VisibleStopPoints
