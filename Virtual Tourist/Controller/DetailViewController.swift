//
//  DetailViewController.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    // MARK: - Properties
    
    var photos: [Photo] = []
    var selectedIndex: Int!
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture(gesture:)))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture(gesture:)))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateImage()
    }
    
    // MARK: - Helper Functions
    
    func updateImage() {
        if let imageData = photos[selectedIndex].image {
            photoImageView.image = UIImage(data: imageData)
        }
        titleLabel.text = photos[selectedIndex].title
    }
    
    // MARK: - Selector Functions
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case .left:
                selectedIndex += 1
                if selectedIndex >= photos.count {
                    selectedIndex = 0
                }
                updateImage()
            case .right:
                selectedIndex -= 1
                if selectedIndex < 0 {
                    selectedIndex = photos.count - 1
                }
                updateImage()
            default:
                print("Neither left swipe nor right swipe was performed.")
            }
        }
    }
    
}
