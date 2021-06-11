import actions from '../actions'
import { connect } from 'react-redux'
import { chain } from 'lodash'
import SelectableContainer from '../components/SelectableContainer'

const sortedVjas = vehicleJourneys => {
	const vjasMapper = x => (vjas, y) => ({ ...vjas, x, y })
	const vjMapper = (vj, x) => vj.vehicle_journey_at_stops.map(vjasMapper(x))

	return chain(vehicleJourneys)
		.map(vjMapper)
		.flatten()
		.reject('dummy')
		.sortBy(['y', 'x'])
		.value()
}

const mapStateToProps = ({ selection, filters, vehicleJourneys }) => ({
	selectionMode: selection.active,
	selectedItems: selection.items || [],
	toggleArrivals: filters.toggleArrivals,
	vehicleJourneysAtStops: sortedVjas(vehicleJourneys)
})

const mapDispatchToProps = (dispatch) => ({
	updateSelectedItems: items => {
		dispatch(actions.updateSelectedItems(items))
	},
	clearSelectedItems: () => dispatch(actions.clearSelectedItems()),
	updateSelectionDimensions: (width, height) => {
		dispatch(actions.updateSelectionDimensions(width, height))
	},
	updateSelectionLocked: bool => {
		dispatch(actions.updateSelectionLocked(bool))
	}
})

export default connect(mapStateToProps, mapDispatchToProps)(SelectableContainer)
