//
//  ViewController.swift
//  GooseBye
//
//  Created by Kishan Patel on 10/20/16.
//  Copyright © 2016 Kishan Patel. All rights reserved.
//

import UIKit

class CredentialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBOutlet weak var credentialValue: UITextField!
    
    @IBAction func letsGoPress() {
        if (credentialValue.text == "123456")
        {
            self.performSegue(withIdentifier: "segueCredentialToHome", sender: nil)
        }
    }

}

