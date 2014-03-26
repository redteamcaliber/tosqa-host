ng = angular.module 'myApp'

ng.config ($stateProvider, navbarProvider ) ->
  $stateProvider.state 'view3',
    url: '/view3'
    templateUrl: 'view3/view.html'
    controller: 'View3Ctrl'
  navbarProvider.add '/view3', 'View3', 13

ng.controller 'View3Ctrl', ($scope, $log) ->

# # use buttons to set variable to values
# ng.controller 'View3Ctrl', ($scope, $modal, $log) ->
# # ModalDemoCtrl = ($scope, $modal, $log) ->
#   $scope.items = [
#     "item1"
#     "item2"
#     "item3"
#   ]
#   $scope.open = ->
#     modalInstance = $modal.open(
#       templateUrl: "myModalContent.html"
#       controller: ModalInstanceCtrl
#       resolve:
#         items: ->
#           $scope.items
#     )
#     modalInstance.result.then ((selectedItem) ->
#       $scope.selected = selectedItem
#       return
#     ), ->
#       $log.info "Modal dismissed at: " + new Date()
#       return

#     return

#   return


# # Please note that $modalInstance represents a modal window (instance) dependency.
# # It is not the same as the $modal service used above.
# ModalInstanceCtrl = ($scope, $modalInstance, items) ->
#   $scope.items = items
#   $scope.selected = item: $scope.items[0]
#   $scope.ok = ->
#     $modalInstance.close $scope.selected.item
#     return

#   $scope.cancel = ->
#     $modalInstance.dismiss "cancel"
#     return

#   return

# angular.module("myApp").service "$modal", ->
#     modalDefaults =
#       backdrop: true
#       keyboard: true
#       modalFade: true
#       templateUrl: "/app/partials/modal.html"

#     modalOptions =
#       closeButtonText: "Close"
#       actionButtonText: "OK"
#       headerText: "Proceed?"
#       bodyText: "Perform this action?"

#     @showModal = (customModalDefaults, customModalOptions) ->
#       customModalDefaults = {}  unless customModalDefaults
#       customModalDefaults.backdrop = "static"
#       @show customModalDefaults, customModalOptions

#     @open = (customModalDefaults, customModalOptions) ->
      
#       #Create temp objects to work with since we're in a singleton service
#       tempModalDefaults = {}
#       tempModalOptions = {}
      
#       #Map angular-ui modal custom defaults to modal defaults defined in service
#       angular.extend tempModalDefaults, modalDefaults, customModalDefaults
      
#       #Map modal.html $scope custom properties to defaults defined in service
#       angular.extend tempModalOptions, modalOptions, customModalOptions
#       unless tempModalDefaults.controller
#         tempModalDefaults.controller = ($scope, $modalInstance) ->
#           $scope.modalOptions = tempModalOptions
#           $scope.modalOptions.ok = (result) ->
#             $modalInstance.close result
#             return

#           $scope.modalOptions.close = (result) ->
#             $modalInstance.dismiss "cancel"
#             return

#           return
#       $modal.open(tempModalDefaults).result




