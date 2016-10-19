//
//  LandscapeViewController.swift
//  Store Search
//
//  Created by N on 2016-10-18.
//  Copyright © 2016 Agaba Nkuuhe. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
    
    var searchResults = [SearchResult]() //Initially empty. SearchVC gives it a real array upon rotation to landscape
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    private var firstTime = true
    private var downloadTasks = [URLSessionDownloadTask]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        
        pageControl.numberOfPages = 0
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        print("deinit \(self)")
        for task in downloadTasks {
            task.cancel()
        }
    }
    
    /*
     - viewWillLayoutSubviews() is called by UIKit as part of the layout phase of your
     view controller. when it first appears on the screen.
     
     - It's the ideal place for changing the frames of your views by hand.
     
     - The scroll view should always be as large as the entire screene, so
     frame = view's bounds.
     
     - The page control is located at the bottom of the screen & spans the width of the
     screen
     */
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        pageControl.frame = CGRect(x: 0,
                                   y: view.frame.size.height - pageControl.frame.size.height,
                                   width: view.frame.size.width,
                                   height: pageControl.frame.size.width)
        
        if firstTime {
            firstTime = false
            tileButtons(searchResults)
        }
    }
    
    /*
     tileButtons(_ searchResults:) calculates how many images need to be placed on the screen & places the buttons on the screen in neat rows and columns.
     
     It is called once when the landscapeViewController is added to the screen.
     
     Calculation:
     
     - Decide how big the grid squares will be & how many squares need to fill up each page. Consider 4 cases:
            1. 480 points, 3.5-inch device (iPad version atm)
            2. 568 points, 4-inch device (iPhone 5, iPhone SE)
            3. 667 points, 4.7-inch device (iPhone 6, 6s, 7)
            4. 736 points, 5.5-inch device (iPhone 6/6s/7 plus)
     
     */
    private func tileButtons(_ searchResults: [SearchResult]) {
        
        var columnsPerPage = 5
        var rowsPerPage = 3
        var itemWidth: CGFloat = 96
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 0
        var marginY: CGFloat = 20
        
        let scrollViewWidth = scrollView.bounds.size.width
        
        switch scrollViewWidth {
        case 568:
            columnsPerPage = 6
            itemWidth = 94
            marginX = 2
        case 667:
            columnsPerPage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
        case 736:
            columnsPerPage = 8
            rowsPerPage = 4
            itemWidth = 92
        default:
            break
        }
        
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth)/2
        let paddingVert = (itemHeight - buttonHeight)/2
        
        var row = 0
        var column = 0
        var x = marginX
        
        for (index, searchResult) in searchResults.enumerated() {
            
            //1. Create the button
            let button = UIButton(type: .system)
            downloadImage(for: searchResult, andPlaceOn: button)
            
            //2 Set the button's frame
            button.frame = CGRect(x: x + paddingHorz,
                                  y: marginY + CGFloat(row)*itemHeight + paddingVert,
                                  width: buttonWidth, height: buttonHeight)
            
            //3 Add the button to the scroll view
            scrollView.addSubview(button)
            
            //4 Use the x and row variables to position the buttons, going from top to bottom (by increasing row)
            row+=1
            if row == rowsPerPage {
                row = 0; x += itemWidth; column += 1
                
                if column == columnsPerPage {
                    column = 0; x += marginX * 2
                }
            }
        }
        
        //Calculate the contentSize for the scroll view based on how many buttons fit on a page and the number of SearchResult objects.
        
        let buttonsPerPage = columnsPerPage * rowsPerPage
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
        
        scrollView.contentSize = CGSize(width: CGFloat(numPages) * scrollViewWidth,
                                        height: scrollView.bounds.size.height)
        
        print("Number of pages: \(numPages)")
        
        //Paging: Set the number of dots that the page control displays to the number of pages calculated.
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
        
    }
    
    /*
     pageChanged(_ sender: UIPageControl) lets us know when the user taps on the Page Control so we can update the scroll view.
     */
    @IBAction func pageChanged(_ sender: UIPageControl) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.scrollView.contentOffset = CGPoint(
                x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage), y: 0)
            }, completion: nil)
        
        
    }
    
    /*
     downloadImage(for searchResult: , andPlaceOn button: ) downloads an image and places it on a button
     
     */
    
    private func downloadImage(for searchResult: SearchResult, andPlaceOn button: UIButton) {
        
        if let url = URL(string: searchResult.artworkSmallURL) {
            let downloadTask = URLSession.shared.downloadTask(with: url) {
                [weak button] url, response, error in
                if error == nil, let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let button = button {
                            button.setImage(image, for: .normal)
                            print("Button image set successfully")
                        }
                    }
                }
            }
            downloadTask.resume()
            downloadTasks.append(downloadTask)
        }
    }
}

extension LandscapeViewController: UIScrollViewDelegate {
    /*
     scrollViewDidScroll(_ scrollView:)
     
     - Figure out what the index of the current page is by looking at the contentOffset property of the scroll view.
     - contentOffset determines how far the scroll view has been scrolled and is updated while dragging the scroll view.
     - Here we calculate when the user has flipped the page. If the content offset gets beyond halfway on the page (width/2), the 
       scroll view will flick to the next page. In that case, we update the pageControl's active page number
     */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let currentPage = Int((scrollView.contentOffset.x + width/2)/width)
        pageControl.currentPage = currentPage
    }
}
