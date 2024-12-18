import actions from '../../actions'
import { connect } from 'react-redux'
import CreateModal from '../../components/tools/CreateModal'

const mapStateToProps = (state, ownProps) => {
  return {
    disabled: ownProps.disabled,
    modal: state.modal,
    vehicleJourneys: state.vehicleJourneys,
    status: state.status,
    stopPointsList: state.stopPointsList,
    missions: state.missions,
    custom_fields: state.custom_fields,
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () =>{
      dispatch(actions.closeModal())
    },
    onAddVehicleJourney: (data, selectedJourneyPattern, stopPointsList, selectedCompany, selectedAccessibilityAssessment) =>{
      dispatch(actions.addVehicleJourney(data, selectedJourneyPattern, stopPointsList, selectedCompany, selectedAccessibilityAssessment))
    },
    onOpenCreateModal: () =>{
      dispatch(actions.openCreateModal())
    },
    onSelect2JourneyPattern: selectedItem =>{
      dispatch(actions.selectJPCreateModal(selectedItem))
    },
    onSelect2Company: selectedItem => {
      dispatch(actions.select2Company(selectedItem))
    },
    onUnselect2Company: () => {
      dispatch(actions.unselect2Company())
    },
    onSelect2AccessibilityAssessment: selectedItem => {
      dispatch(actions.select2AccessibilityAssessment(selectedItem))
    },
    onUnselect2AccessibilityAssessment: () => {
      dispatch(actions.unselect2AccessibilityAssessment())
    }
  }
}

const AddVehicleJourney = connect(mapStateToProps, mapDispatchToProps)(CreateModal)

export default AddVehicleJourney
