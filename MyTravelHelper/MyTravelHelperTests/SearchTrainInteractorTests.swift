//
//  SearchTrainInteractorTests.swift
//  MyTravelHelperTests
//

import XCTest
@testable import MyTravelHelper

class SearchTrainInteractorTests: XCTestCase {
    let presenter = SearchTrainPresenterMock()
    var searchTrainInteractor: SearchTrainInteractor!
    let serviceManagerMock = ApiManagerMock()
    let reachabiliityMock = ReachablityMock()
    let xmlDecoder = XMLDecoderMock()

    override func setUp() {
        searchTrainInteractor = SearchTrainInteractor(serviceManager: serviceManagerMock, reachablity: reachabiliityMock,
                                        xmlDecoder: xmlDecoder)
        searchTrainInteractor.presenter = presenter
    }

    func testfetchAllStation() {
        reachabiliityMock.isAvailable = true
        serviceManagerMock.resposeData = Data()
        searchTrainInteractor.fetchallStations()
        XCTAssertTrue(presenter.stationList.count == 1)
        let station = presenter.stationList.first
        XCTAssertTrue(station?.stationDesc == "Belfast")
        XCTAssertTrue(station?.stationLatitude == 70.93)
        XCTAssertTrue(station?.stationLongitude == -3.857)
        XCTAssertTrue(station?.stationCode == "abcd")
        XCTAssertTrue(station?.stationId == 228)
    }

    func testfetchTrainBetweenSourceAndDestinationWhenNoInternetConnection() {
        reachabiliityMock.isAvailable = false
        searchTrainInteractor.fetchTrainsFromSource(sourceCode: "Belfast", destinationCode: "Lisburn")
        XCTAssertTrue(presenter.isNoInterNetAvailabilityCalled)
    }

    func testfetchTrainBetweenSourceAndDestinationWhenTrainListIsEmpty() {
        reachabiliityMock.isAvailable = true
        serviceManagerMock.resposeData = Data()
        xmlDecoder.isTrainListEmpty = true
        searchTrainInteractor.fetchTrainsFromSource(sourceCode: "Belfast", destinationCode: "Lisburn")
        XCTAssertTrue(presenter.isNoTrainAvailabilityCalled)
    }

    func testfetchTrainBetweenSourceAndDestinationWithDestinationDetails() {
           reachabiliityMock.isAvailable = true
           serviceManagerMock.resposeData = Data()
            xmlDecoder.isTrainListEmpty = false
           xmlDecoder.isTrainMovementListEmpty = false
           searchTrainInteractor.fetchTrainsFromSource(sourceCode: "Belfast", destinationCode: "Lisburn")
           XCTAssertTrue(serviceManagerMock.fetchTrainMovementCalled)
           XCTAssertTrue(presenter.stationTrainList.count == 0)
       }

    override func tearDown() {
        searchTrainInteractor = nil
    }
}

class XMLDecoderMock: DecoderProtoccol {
    let station = Station(desc: "Belfast", latitude: 70.93, longitude: -3.857, code: "abcd", stationId: 228)
    var train = StationTrain(trainCode: "t123",
                             fullName: "train",
                             stationCode: "stationcode",
                             trainDate: "9 may 2021",
                             dueIn: 23,
                             lateBy: 0,
                             expArrival: "12:39",
                             expDeparture: "04:20")
    let trainMovement = TrainMovement(trainCode: "t123", locationCode: "abcd", locationFullName: "asdf", expDeparture: "train")
    var isTrainListEmpty = true
    var isTrainMovementListEmpty = true

    func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
        if type == Stations.self {
            return Stations(stationsList: [station]) as! T
        } else if type == StationData.self {
            if isTrainListEmpty {
                return StationData(trainsList: []) as! T
            } else {
                if isTrainMovementListEmpty {
                return StationData(trainsList: [train]) as! T
                } else {
                    train.destinationDetails = trainMovement
                    return StationData(trainsList: [train]) as! T
                }
            }
        } else if type == TrainMovementsData.self {
            if isTrainMovementListEmpty {
                return TrainMovementsData(trainMovements: []) as! T
            } else {
                return TrainMovementsData(trainMovements: [trainMovement]) as! T
            }
        }
        return TrainMock() as! T
    }
}

class TrainMock {}

class SearchTrainPresenterMock: InteractorToPresenterProtocol {
    func showNoStationAvailabileMessage() {
        
    }
    
    var stationList = [Station]()
    var stationTrainList = [StationTrain]()

    func stationListFetched(list:[Station]) {
        stationList = list
    }

    func fetchedTrainsList(trainsList:[StationTrain]?) {
        stationTrainList = trainsList!
    }

    var isNoTrainAvailabilityCalled = false

    func showNoTrainAvailbilityFromSource() {
        isNoTrainAvailabilityCalled = true
    }

    var isNoInterNetAvailabilityCalled = false
    var isNoStationAvailabilityCalled = false

    func showNoInterNetAvailabilityMessage() {
        isNoInterNetAvailabilityCalled = true
    }

    func showNoStationAvailabilityMessage() {
        isNoStationAvailabilityCalled = true
    }
}

class ApiManagerMock: ApiManagerProtocol {
    var resposeData: Data?
    func fetchAllStations(completionHandler: @escaping (Data?) -> Void) {
        completionHandler(resposeData)
    }

    func fetchTrainsFromSource(sourceCode: String, completionHandler: @escaping (Data?) -> Void) {
        completionHandler(resposeData)
    }

    var fetchTrainMovementCalled = false

    func fetchTrainMovement(trainCode: String, trainDate: String, completionHandler: @escaping (Data?) -> Void) {
        fetchTrainMovementCalled = true
        completionHandler(resposeData)
    }
}

class ReachablityMock: Reachable {
    var isAvailable = true

    func isNetworkReachable() -> Bool {
        return isAvailable
    }
}
