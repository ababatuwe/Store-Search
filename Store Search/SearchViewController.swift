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
    
    var searchResults: [SearchResult] = []
    var hasSearched = false
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        tableView.rowHeight = 80
        
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        searchBar.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func iTunesURL(searchText: String) -> URL {
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let urlString = String(format: "https://itunes.apple.com/search?term=%@", escapedSearchText!)
        let url = URL(string: urlString)
        
        return url!
    }
    
    /*
    * String(contentsOf:, enconding:) returns a new string object with the data it receives from the server
    * at the other end of the URL.
    *
    * Because things can go wrong, for example, the network may be down and the server cannot be reached -
    * you're putting this in a do-try-catch block. If there is a problem, the code jumps to the catch section
    * and the error variable contains more details about the error.
    *
    * return nil to signal that the request failed
    */
    func performStoreRequest(with url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print("Download Error: \(error)")
            return nil
        }
    }
    
    /*
     * keys will always be strings
     * values can be anything String, number or boolean that's why the type of values is "Any"
     * 
     * The chance is small but it's possible that this conversion of string to Data fails - for example, if the text from the string cannot be represented in the encoding you've chosen. That's why you're using a guard statmenet. guard let works like if let, it unwraps the optionals for you. but if unwrapping fails, i.e. if json.data(...) returns nil, the guard's else block is executed and you return nil to indicate that parse(json) failed. This "should" never happen in our app, but it's good to be vigilant about this kind of thing. (Never say never!)
     
     * If everything went OK - and 99.999% of the time it will! - you convert the Data object into a Dictionary using JSONSerialization.jsonObject(...). Or atleast, you hope you can convert it into a dictionary...
     */
    func parse(json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8, allowLossyConversion: false) else { return nil }
        
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
    
    func parse(_ dictionary: [String: Any]) -> [SearchResult]{
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
    
    func kindForDisplay(_ kind: String) -> String {
        switch kind {
        case "album" : return "Album"
        case "audiobook" : return "Audio Book"
        case "book" : return "Book"
        case "ebook" : return "E-Book"
        case "feature-movie" : return "Movie"
        case "music-video" : return "Music Video"
        case "podcast" : return "Podcast"
        case "software" : return "App"
        case "song" : return "Song"
        case "tv-episode" : return "TV Episode"
        default: return kind
        }
    }
    
    
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            
            hasSearched = true
            searchResults = []
            
            let url = iTunesURL(searchText: searchBar.text!)
            print("URL: \(url)")
            
            if let jsonString = performStoreRequest(with: url) {
                if let jsonDictionary = parse(json: jsonString) {
                    searchResults = parse(jsonDictionary)
                    searchResults.sort(by: <)
                    tableView.reloadData()
                    return
                }
            }
            showNetworkError()
        }
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
   
}

extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            
            let searchResult = searchResults[indexPath.row]
            
            cell.nameLabel.text = searchResult.name
            
            if searchResult.artistName.isEmpty {
                cell.artistNameLabel.text = "Unknown"
            } else {
                cell.artistNameLabel.text = String(format: "%@ (%@)", searchResult.artistName, kindForDisplay(searchResult.kind))
            }
            
            return cell
        }
        
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
}


