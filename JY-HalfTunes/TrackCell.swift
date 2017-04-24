//
//  TrackCell.swift
//  JY-HalfTunes
//
//  Created by atom on 2017/4/20.
//  Copyright © 2017年 atom. All rights reserved.
//

import UIKit

protocol TrackCellDelegate {
    func pauseTapped(cell: TrackCell)
    func resumeTapped(cell: TrackCell)
    func cancelTapped(cell: TrackCell)
    func downloadTapped(cell: TrackCell)
}

class TrackCell: UITableViewCell {
    var delegate: TrackCellDelegate?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    var downLoadblock: downloadblock!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    typealias downloadblock = () -> Void

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func pauseOrresumeTapped(_ sender: Any) {
        if (pauseButton.titleLabel?.text == "Pause") {
            delegate?.pauseTapped(cell: self)
        } else {
            delegate?.resumeTapped(cell: self)
        }
    }
    @IBAction func cancelTapped(_ sender: Any) {
        delegate?.cancelTapped(cell: self)
    }
    @IBAction func downloadTapped(_ sender: Any) {
        downLoadblock()
        delegate?.downloadTapped(cell: self)
    }

}
