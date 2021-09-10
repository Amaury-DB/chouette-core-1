import React, { useEffect } from 'react'
import PropTypes from 'prop-types'
import { pick } from 'lodash'

import store from '../shape.store'
import eventEmitter, { events } from '../shape.event-emitter'
import { onWaypointsUpdate$, onMapZoom$ } from '../shape.observables'
import { getWaypoints } from '../shape.selectors'

import { useStore } from '../../../helpers/hooks'

import { useMapController, useValidatorController } from '../controllers/ui'
import {
  useRouteController,
  useLineController,
  useShapeController,
  useUserPermissionsController
} from '../controllers/data'

import MapWrapper from '../../../components/MapWrapper'
import NameInput from './NameInput'
import List from './List'
import CancelButton from './CancelButton'
import SaveButton from './SaveButton'

const mapStateToProps = state => ({
  ...pick(state, ['name', 'permissions', 'style', 'routeFeatures']),
  waypoints: getWaypoints(state)
})
export default function ShapeEditorMap({ isEdit, baseURL, redirectURL }) {
  // Store
  const { routeFeatures: features, name, permissions, style, waypoints } = useStore(store, mapStateToProps)

  // Evvent Handlers
  const onMapInit = map => setTimeout(() => eventEmitter.emit(events.initMap, map), 0) // Need to do this to ensure that controllers can subscribe to event before it is fired
  const onWaypointZoom = waypoint => eventEmitter.emit(events.waypointZoom, waypoint)
  const onDeleteWaypoint = waypoint => eventEmitter.emit(events.waypointDeleteRequest, waypoint)
  const onSubmit = _event => eventEmitter.emit(events.submitShape)
  const onConfirmCancel = _event => window.location.replace(redirectURL)

  // Controllers
  useMapController()
  useValidatorController()

  useRouteController(isEdit)
  useLineController(isEdit, baseURL)
  useUserPermissionsController(isEdit, baseURL)
  useShapeController(isEdit, baseURL)

  useEffect(() => {
    onWaypointsUpdate$.subscribe(_state => eventEmitter.emit(events.waypointUpdated))
    onMapZoom$.subscribe(data => eventEmitter.emit(events.mapZoom, data))

    return () => {
      eventEmitter.complete()
    }
  }, [])

  return (
    <div>
      <CancelButton onConfirmCancel={onConfirmCancel} />
      <SaveButton isEdit={isEdit} permissions={permissions} onSubmit={onSubmit} />
      <div className="col-lg-8 col-lg-offset-2 col-md-8 col-md-offset-2 col-sm-10 col-sm-offset-1">
        <div className="row">
          <NameInput name={name} />
        </div>
        <div className="row">
          <div className="col-md-12">
            <h4 className="underline">Carte</h4>
            <div className="openlayers_map">
              <MapWrapper features={features} style={style} onInit={onMapInit} />
            </div>
          </div>
        </div>
        <div className="row mt-lg">
          <div className="col-md-12">
            <h4 className="underline">Liste</h4>
            <List waypoints={waypoints} onWaypointZoom={onWaypointZoom} onDeleteWaypoint={onDeleteWaypoint} />
          </div>
        </div>
      </div>
    </div>
  )
}

ShapeEditorMap.propTypes = {
  isEdit: PropTypes.bool.isRequired,
  baseURL: PropTypes.string.isRequired,
  redirectURL: PropTypes.string.isRequired,
}
