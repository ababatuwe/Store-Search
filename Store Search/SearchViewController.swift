//
//  ViewController.swift
//  Store Search
//
//  Created by N on 2016-10-12.
//  Copyright © 2016 Agaba Nkuuhe. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var landscapeViewController: LandscapeViewController?
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    var searchResults: [SearchResult] = []
    var hasSearched = false
    var isLoading = false
    
    var dataTask: URLSessionDataTask?
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0)
        tableView.rowHeight = 80
        
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        searchBar.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func iTunesURL(searchText: String, category: Int) -> URL {
        
        let entityName: String
        switch category {
            case 1: entityName = "musicTrack"
            case 2: entityName = "software"
            case 3: entityName = "ebook"
            default: entityName = ""
        }
        
        
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlString = String(format: "https://itunes.apple.com/search?term=%@&limit=200&entity=%@", escapedSearchText, entityName)
        let url = URL(string: urlString)
        
        return url!
    }
    
    /*
     * keys will always be strings
     * values can be anything String, number or boolean that's why the type of values is "Any"
     * 
     * The chance is small but it's possible that this conversion of string to Data fails - for example, if the text from the string cannot be represented in the encoding you've chosen. That's why you're using a guard statmenet. guard let works like if let, it unwraps the optionals for you. but if unwrapping fails, i.e. if json.data(...) returns nil, the guard's else block is executed and you return nil to indicate that parse(json) failed. This "should" never happen in our app, but it's good to be vigilant about this kind of thing. (Never say never!)
     
     * If everything went OK - and 99.999% of the time it will! - you convert the Data object into a Dictionary using JSONSerialization.jsonObject(...). Or atleast, you hope you can convert it into a dictionary...
     
     * Removed the guard statemenet and changed the parameter from String to Data. Previously this method took a String object and converted it into a Data object that it passed to JSONSerialization.jsonObject(...). Now you already have the JSON text in a Data object, so you no longer have to bother with the string.
     */
    func parse(json data: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("JSON Error: \(error)")
            return nil
        }
    }
    
    /*
     * Add an alert to handle potential errors. It's inevitable that something goes wrong somewhere, so it's 
     * best to be prepared
     * Present an alert controller with an error message.
     */
    func showNetworkError(){
        let alert = UIAlertController(title: "Whoops...", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    /*
     This method goes through the top-level dictionary and looks at each search result in turn. Here's what happens step-by-step:
     1. A bit of defensive programming to make sure the dictionary has a key named results that contains an array. it probably will, but better safe than sorry
     2. Once it is satisfied that array exists, the method uses a for in loop to look at each of the array's elements in turn
     3. Each of the elements from the array is another dictionary. A small wrinkle: the type of resultDict isn't Dictionary as we'd like it to be, but Any, because the contents of the array could in theory be anything.
     
     To make sure these objects reslly do represent dictionaries, yu have to cast them to the right type first. You're using the optional cast as? here as another defensive measure. In theory, it's possible resultDict doesn't actually hold a [String: Any] dictionary and then you don't want to continue
     
     4. For each of the dictionaries, you print out the value of its wrapperType and kind fields. Indexing a dictionary always gives you an optional, which is why you're using if let to unwrap these two values. An because the dictionary only contains values of type Any, you also cast the more useful String.
     */
    
    func parse(jsonDictionary dictionary: [String: Any]) -> [SearchResult]{
        //1
        guard let array = dictionary["results"] as? [Any] else {
            print("Expected 'results' array")
            return []
        }
        var searchResults = [SearchResult]()
        for resultDict in array {
            //3
            if let resultDict = resultDict as? [String: Any] {
                //4
                var searchResult: SearchResult?
                if let wrapperType = resultDict["wrapperType"] as? String {
                    switch wrapperType {
                        case "track":
                            searchResult = parse(track: resultDict)
                        case "audiobook":
                            searchResult = parse(audiobook: resultDict)
                        case "software":
                            searchResult = parse(software: resultDict)
                        default:
                            break
                    }
                } else if let kind = resultDict["kind"] as? String, kind == "ebook" {
                    searchResult = parse(ebook: resultDict)
                }
                
                if let result = searchResult {
                    searchResults.append(result)
                }
            }
        }
        return searchResults
    }
    
    /*
     * Instantiate a new SearchResult object, then get the values out of the dictionary and put them into the 
     * SearchResult's properties. 
     *
     * All of these things are strings except the track price, which is a number. Because the dictionary is defined as 
     * having Any values, you first need to cast to String and Double here.
     */
    func parse(track dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["trackPrice"] as? Double {
            searchResult.price = price
        }
        
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    //Audiobooks don't have a "kind" field, so you have to set the kind property to "audiobook" yourself
    func parse(audiobook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["collectionName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["collectionViewUrl"] as! String
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["collectionPrice"] as? Double {
            searchResult.price = price
        }
        
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    func parse(software dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["price"] as? Double {
            searchResult.price = price
        }
        
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    //Ebooks don't have a primaryGenreName field, but an array of genres. You use joined(separator) method to glue these genre names into a single string, separated by commas.
    func parse(ebook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallURL = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeURL = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["price"] as? Double {
            searchResult.price = price
        }
        
        if let genres: Any = dictionary["genres"]{
            searchResult.genre = (genres as! [String]).joined(separator: ", ")
        }
        return searchResult
    }
    

    
    /*
     * 1. Create the URL object with the search text like before
     *
     * 2. Obtain the URLSession object. This grabs the standard "shared" session, which uses a default configuration with respect to
     *    caching, cookies, and other web stuff.
     *    If you want to use a different config - eg. to restrict networking to when Wi-Fi is available but not when there is only
     *    cellular access - then you have to creat your own URLSessionConfiguration and URLSession objects. But for this app the
     *    default one will be fine
     *
     * 3. Create the data task. Data tasks are for sending HTTPS GET requests to the server at url. the code from the completion
     *    handler will be invoked when the data task has received the reply from the server.
     *
     * 4. Inside the closure you're given three parameters: data, response and error. These are all optionals so they can be nil and
     *    have to be unwrapped before you can use them. If there was a problem, error contains an Error object describing what went
     *    wrong. This happens when the server cannot be reached or the network is down or some other hardware failure. If error is
     *    nil, the communication with the server succeeded; response holds the server's response code and headers, and data contains
     *    the actual thing that was sent from the server, in this case a blob of JSON. For now you simply use a print() to show *
     *    success or failure.
     *
     *    Success:
     *    Unwrap the optional object from the data parameter and give it to parse(json) to convert it into a dictionary. Call parse(jsonDictionary) to convert the dictionary contents into SearchResult objects. Finally, sort the results and put everything into the table view. The completion handler won't be performed on the main thread. Because URLSession does all the networking asynchronously, it will also call the completion handler on a background thread. Parsing the JSON and sorting the list of search results could potentially take a while(long enough to be noticeable). You don't want to block the main thread while that is happening, so it;s preferable that this happens in the background too.When the time comes to update the UI, you need to switch back to the main thread. Those are the rules. That's why you wrap the reloading of the table view into DispatchQueue.main.async on the main queue. If you forget ot do this, your app may still appear to work. That's the insidious thing about working with multiple threads. However, it may also crash in all kinds of mysterious ways. So remember, UI stuff should always happen on the main thread.
     *
     * 5. Finally, once you have created the data task, call resume() to start it. This sends the request to the server. That all
     *    happens on a background thread, so the app is immediately free to continue (URLSession is as async as they come)
     *
     */
    func performSearch(){
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            
            dataTask?.cancel()
            isLoading = true
            tableView.reloadData()
            
            hasSearched = true
            searchResults = []
            
            //1
            let url = iTunesURL(searchText: searchBar.text!, category: segmentControl.selectedSegmentIndex)
            //2
            let session = URLSession.shared
            //3
            dataTask = session.dataTask(with: url, completionHandler: {
                data, response, error in
                //4
                if let error = error as? NSError, error.code == -999 {
                    return
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let data = data, let jsonDictionary = self.parse(json: data) {
                        self.searchResults = self.parse(jsonDictionary: jsonDictionary)
                        self.searchResults.sort(by: <)
                        
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.tableView.reloadData()
                        }
                        return
                    }
                } else {
                    print("Failure! \(response)")
                }
                DispatchQueue.main.async {
                    self.hasSearched = false
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.showNetworkError()
                }
            })
            //5
            dataTask?.resume()
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            let searchResult = searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }
    
    /*
     willTransition is invoked when the device is flipped over. You can override this method to show (and hide) the new
     LandscapeViewController.
     
     This method isn't just invoked on device rotations but any time the trait collection for the view controller changes. So what is a trait collection? It is a collection of traits where a trait can be:
     - the horizontal size class
     - the vertical size class
     - the display scale (is this Retina screen or not?)
     - the user interface idiom (is this an iPhone or iPad?)
     - the preferred Dynamic Type font size
     - and a few other things
     
     Whenever one or more of these traits change, for whatever reason, UIKit calls willTransition(to:with:) to give the view controller a chance to adapt to the new traits.
     
     SIZE CLASSES:
     
     This feature allows you to design a UI that is independent of the device's actual dimensions or orientation. With size classes, you can create a single storyboard that works across all devices, from iPhone to iPad - a so called "universal storyboard".
     
     There's two size classes: Horizontal and vertical, and each can have two values: compact or regular. The combination of these four things creates the following possibilities
     
     
     horizontal
     ------------------------------------>
     |                   Compact            Regular
     |               +---------------+---------------+
     |               |               |               |
     |               |   iPhone      |    iPhone     |
     |   Compact     |  Landscape    |      6+       |
     |               |  (except 6+)  |   Landscape   |
     vertical  |               |               |               |
     |               |               |               |
     |               +---------------+---------------+
     |               |               |               |
     |               |    iPhone     |    iPad       |
     |   Regular     |   portrait    |   Portait     |
     |               |               |  Landscape    |
     |               |               |               |
     |               |               |               |
     V               +---------------+---------------+
     
     iPhone in portrait:
     Horizontal size class: compact
     Vertical size class: regular
     
     when iPhone is rotated to landscape:
     Horizontal size class: compact
     Vertical size class: compact
     
     The horizontal size class doesn't change and stays compact in both portrait and landscape orientations - except on the iPhone 6s Plus and 7 Plus, that is.
     
     What this boils down to is that to detect an iPhone rotation, you just have to look at how the vertical size class changed.
     That's exactly what the switch statement does.
     
     */
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        switch newCollection.verticalSizeClass {
        case .compact:
            showLandscape(with: coordinator)
        case .regular, .unspecified:
            hideLandscape(with: coordinator)
            
        }
    }
    
    /*
     Previously, we used present(animated, completion) or make a segue to show the new modal screen. Here, however, you add the new LandscapeViewController as a child view controller of SearchViewController.
     
     1. It should never happen that the app instantiates a second landscape view when you're already looking at one. The guard that landscapeViewController is still nil codified this requirement. If it should happen that this condition doesn't hold - we're already showing the landscape view - then we simply return right away.
     
     2. Find the scene with the ID "LandscapeViewController" in the storyboard and instantiate it. Because you don't have a segue you need to do this manually. This is why you filled in that Storyboard ID field in the Identity inspector. The landscapeViewController instance variable is an optional so you need to unwrap it before you can continue.
     
     3. Set the size and position of this new view controller. This makes the landscape view just as big as the SearchViewController, covering the entire screen. The frame is the rectangle that descibes the view's position and size you usually set its frame. The bounds is also a rectangle but seen from the inside of the view. Because SearchViewController's view is the superview here, the frame of the landscape view must be made equal to the SearchViewController's bounds.
     
     4. These are the minimum required steps to add the contents of one view controller to another, in this order:
        - 1st, add the landscape controller's view as a subview. This places it on top of the table view, search bar and segmented 
          control.
        - Then tell the SearchVC that the LandscapeVC is now managing that part of the screen, using addChildViewController(). If 
          you forget this step then the new view controller may not always work correctly.
        - Tell the new view controller that it now has a parent view controller with didMove(toParentViewController).
     
     In this new arrangement, SearchViewController is the "parent" view controller, and LandscapeViewController is the "child". In 
     other words, the Landscape screen is embedded inside the SearchViewController.
     */
    
    func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        //1
        guard landscapeViewController == nil else { return }
        //2
        landscapeViewController = storyboard?.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
        
        if let controller = landscapeViewController {
            controller.searchResults = searchResults // Handover the searchResults to landscapeViewController upon rotation to landscape
            //3
            controller.view.frame = view.bounds
            controller.view.alpha = 0
            //4
            view.addSubview(controller.view)
            addChildViewController(controller)
            
            coordinator.animate(alongsideTransition: { _ in
                
                controller.view.alpha = 1
                
                //Make keyboard disappear
                self.searchBar.resignFirstResponder()
                
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
                }, completion: { _ in
                    controller.didMove(toParentViewController: self)
            })
        }
    }
    
    /*
        First call willMove(toParentViewController: nil) to tell the new view controller that it is leaving the view controller
        hierarchy (it no longer has a parent), then you remove its view from the screen, and finally 
        removeFromParentViewController() truly disposes of the view controller.
     
        You also set the instance variable to nil in order to remove the last strong reference to the LandscapeViewController object
        now that you're done with it.
     */
    
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeViewController {
            controller.willMove(toParentViewController: nil)
            
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 0
                }, completion: { _ in
                    controller.view.removeFromSuperview()
                    controller.removeFromParentViewController()
                    self.landscapeViewController = nil
            })
        }
    }
    
    
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
   
}

extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath)
            
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            
            return cell
        } else if searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            
            let searchResult = searchResults[indexPath.row]
            cell.configure(for: searchResult)
            return cell
        }
        
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
    }
    
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}


