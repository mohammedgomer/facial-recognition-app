//
//  FirstViewController.swift
//  PhotoAlbumPortfolio2
//
//  Created by Gheta on 25/04/2019.
//  Copyright © 2019 Mohammed Omer. All rights reserved.
//

// imporitgn UIKIT library
import UIKit

// First page view controller
class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // Start button which segues onto the main page
    @IBAction func theStartButton(_ sender: Any) {
         performSegue(withIdentifier: "startIdentifier", sender: self)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
