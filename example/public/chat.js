(function () {

    Array.prototype.search = function (fn) {
        var found = null;
        this.some(function (item) {
            if (fn(item)) {
                found = item;
                return true;
            }
        });
        return found;
    };


    var chat = angular.module('sinapse.chat', ['ngRoute']);

    chat.config(function ($locationProvider, $routeProvider) {
        $locationProvider.html5Mode(true);

        $routeProvider.when('/rooms/:room_id', {
            templateUrl: 'templates/room.html',
            controller: 'RoomCtrl'
        });
    });


    function SinapseService($rootScope, $http, user) {
        var connected = false;

        function broadcast(type, data) {
            $rootScope.$apply(function () {
                $rootScope.$broadcast('sinapse:' + type, data);
            });
        }

        function connect() {
            if (connected) return;
            var source = new EventSource('http://localhost:9000/?access_token=' + user.token);

            source.addEventListener('authentication', function (event) {
                console.log('sinapse:authentication', event.data);
            });

            source.onmessage = function (event) {
                broadcast('message', JSON.parse(event.data));
            };

            source.onerror = function () {
                connected = false;
                broadcast('error');
            };

            source.onclose = function () {
                connected = false;
                broadcast('close');
            };
            connected = true;
        }

        return function (room_id) {
            $http.post('/rooms/' + room_id + '/subscribe').success(connect);
        };
    }
    chat.service('$sinapse', SinapseService);


    function RoomListCtrl($scope, rooms) {
        $scope.rooms = rooms;
    }
    chat.controller('RoomListCtrl', RoomListCtrl);


    function RoomCtrl($scope, rooms, $routeParams, $sinapse) {
        $scope.room = rooms.search(function (room) {
            return room.id == $routeParams.room_id;
        });
        $scope.messages = [];

        if ($scope.room) {
            $scope.$on('sinapse:message', function (_, message) {
                if (message.room_id == $scope.room.id) {
                    $scope.messages.push(message);
                }
            });
            $sinapse($scope.room.id);
        }
    }
    chat.controller('RoomCtrl', RoomCtrl);


    function MessageNewCtrl($scope, $http, user) {
        $scope.message = {
            user_name: user.name,
            body: ''
        };

        $scope.publish = function () {
            if ($scope.form.$invalid) return;

            var req = $http.post('/publish', {
                room_id: $scope.room.id,
                body: $scope.message.body
            });

            req.success(function () {
                $scope.message.body = '';
                console.log("message published");
            });

            req.error(function () {
                console.error("message not published");
            });
        };
    }
    chat.controller('MessageNewCtrl', MessageNewCtrl);

}());
