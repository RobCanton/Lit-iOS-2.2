
import UIKit

class MXTableViewController: UITableViewController {
    var location: Location?
    
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var numberTextVIew: UITextView!
    @IBOutlet weak var websiteTextView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        tableView.backgroundColor = UIColor(white: 0.10, alpha: 1.0)
        
        let key = mainStore.state.viewLocationKey
        let locations = mainStore.state.locations
        
        for location in locations {
            if location.getKey() == key {
                self.location = location
            }
        }
        
        tableView.estimatedRowHeight = 100.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let text = self.location?.getDescription()
        descLabel.numberOfLines = 0
        descLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        descLabel.text = text
        
        descLabel.sizeToFit()
        
        addressTextView.text = location?.getAddress()
        numberTextVIew.text  = location?.getNumber()
        websiteTextView.text = location?.getWebsite()
        
        
        tableView.reloadData()
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.item == 0 {
            return UITableViewAutomaticDimension
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    

    
}
