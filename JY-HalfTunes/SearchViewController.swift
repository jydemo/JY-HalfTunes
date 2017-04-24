//
//  SearchViewController.swift
//  JY-HalfTunes
//
//  Created by atom on 2017/4/20.
//  Copyright © 2017年 atom. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    var activeDownloads = [String: Download]()
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var searchresults = [Track]()
    
    fileprivate lazy var tapRecognizer: UITapGestureRecognizer = {
        var tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyborad))
        return tapRecognizer
    }()
    
    @objc fileprivate func dismissKeyborad() {
        searchBar.resignFirstResponder()
    }
    
    fileprivate lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView()
    }
    
    fileprivate func updateSearchResults(_ data: Data?) {
        searchresults.removeAll()
        do {
            if let data = data, let response = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: AnyObject] {
                if let array = response["results"] {
                    for trackDict in array as! [AnyObject] {
                        if let trackDict = trackDict as? [String: AnyObject], let previewURL = trackDict["previewUrl"] as? String {
                            let name = trackDict["trackName"] as? String
                            let artist = trackDict["artistName"] as? String
                            searchresults.append(Track(name: name, artist: artist, previewUrl: previewURL))
                        } else {
                            print("Not a dictionary")
                        }
                    }
                } else {
                     print("Results key not found in dictionary")
                }
            } else {
                print("JSON Error")
            }
        } catch let error as NSError {
             print("Error parsing results: \(error.localizedDescription)")
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.setContentOffset(.zero, animated: false)
        }
    }
    
    fileprivate func startDownload(_ track: Track) {
        if let urlString = track.previewUrl, let url = URL(string: urlString) {
            let download = Download(url: urlString)
            download.downloadTask = downloadsSession.downloadTask(with: url)
            download.downloadTask?.resume()
            download.isDownloading = true
            activeDownloads[download.url] = download
        }
    }
    
    fileprivate func pauseDownload(_ track: Track) {
        if let urlString = track.previewUrl, let download = activeDownloads[urlString] {
            if (download.isDownloading) {
                download.downloadTask?.cancel(byProducingResumeData: { (data) in
                    if data != nil {
                        download.resumeData = data!
                    }
                })
                download.isDownloading = false
            }
        }
    }
    
    fileprivate func  cacelDownload(track: Track) {
        if let urlString = track.previewUrl, let download = activeDownloads[urlString] {
            download.downloadTask?.cancel()
            activeDownloads[urlString] = nil
        }
    }
    
    
    
    // Called when the Resume button for a track is tapped
    fileprivate func resumeDownload(_ track: Track) {
        if let urlString = track.previewUrl, let download = activeDownloads[urlString] {
            if let resumeData = download.resumeData {
                download.downloadTask = downloadsSession.downloadTask(withResumeData: resumeData)
                download.downloadTask!.resume()
                download.isDownloading = true
            } else if let url = URL(string: download.url) {
                download.downloadTask = downloadsSession.downloadTask(with: url)
                download.downloadTask!.resume()
                download.isDownloading = true
            }
        }
    }
    
    fileprivate func playDownload(_ track: Track) {
        //let urlString = track.previewUrl, let url =
    }
    
    fileprivate func local(filePathForURL previewURL: String) -> URL? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        if let url = URL(string: previewURL) {
            let lastPathCompontent = url.lastPathComponent
            let fullPath = documentsPath.appendingPathComponent(lastPathCompontent)
            return URL(fileURLWithPath: fullPath)
        }
        return nil
    }
    
    fileprivate func local(fileExistsForTrack track: Track) -> Bool {
        if let urlString = track.previewUrl, let localURL = local(filePathForURL: urlString) {
            var isDir: ObjCBool = false
            let path = localURL.path
            return FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        }
        return false
    }
    
    func track(indexFor downloadTask: URLSessionDownloadTask) -> Int? {
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            for (index, track) in searchresults.enumerated() {
                if url == track.previewUrl! {
                    return index
                }
            }
        }
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyborad()
        
        if !searchBar.text!.isEmpty {
            if dataTask != nil {
                dataTask?.cancel()
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let expectedCharSet = CharacterSet.urlQueryAllowed
            let searchTerm = searchBar.text!.addingPercentEncoding(withAllowedCharacters: expectedCharSet)!
            let url = URL(string: "https://itunes.apple.com/search?media=music&entity=song&term=\(searchTerm)")
            dataTask = defaultSession.dataTask(with: url!){ (data, response, error) in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                if let error = error {
                    print(error.localizedDescription)
                } else if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self.updateSearchResults(data)
                    }
                }
                
            }
            dataTask?.resume()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
}
extension SearchViewController: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let originalURL = downloadTask.originalRequest?.url?.absoluteString, let destinationURL = local(filePathForURL: originalURL) {
            print(destinationURL)
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: destinationURL)
            } catch {
                print(error.localizedDescription)
            }
            do {
                try fileManager.copyItem(at: location, to: destinationURL)
            } catch let error as NSError {
                 print("Could not copy file to disk: \(error.localizedDescription)")
            }
        }
        
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            activeDownloads[url] = nil
            if let trackIndex = track(indexFor: downloadTask) {
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [IndexPath(row: trackIndex, section: 0)], with: .none)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let downloadUrl = downloadTask.originalRequest?.url?.absoluteString, let download = activeDownloads[downloadUrl] {
            download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .binary)
            if let trackIndex = track(indexFor: downloadTask), let trackCell = tableView.cellForRow(at: IndexPath(row: trackIndex, section: 0)) as? TrackCell {
                DispatchQueue.main.async {
                    trackCell.progressView.progress = download.progress
                    trackCell.progressLabel.text = String(format: "%.1f%% of %@", download.progress * 100, totalSize)
                }
            }
        }
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchresults.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackCell
        cell.delegate = self
        cell.downLoadblock = {
            print("downloading")
        }
        let track = searchresults[indexPath.row]
        var showDownloadControls = false
        if let download = activeDownloads[track.previewUrl!] {
            showDownloadControls = true
            cell.progressView.progress = download.progress
            cell.progressLabel.text = (download.isDownloading) ? "Downloading..." : "Paused"
            let title = (download.isDownloading) ? "Pause" : "Resume"
            cell.pauseButton.setTitle(title, for: .normal)
        }
        cell.progressView.isHidden = !showDownloadControls
        cell.progressLabel.isHidden = !showDownloadControls
        let downloaded = local(fileExistsForTrack: track)
        cell.selectionStyle = downloaded ? .gray : .none
        cell.downloadButton.isHidden = downloaded || showDownloadControls
        cell.pauseButton.isHidden = !showDownloadControls
        cell.cancelButton.isHidden = !showDownloadControls
        cell.titleLabel.text = track.name
        cell.artistLabel.text = track.artist
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62.0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = searchresults[indexPath.row]
        if local(fileExistsForTrack: track) {
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SearchViewController: TrackCellDelegate {
    
    func pauseTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchresults[indexPath.row]
            pauseDownload(track)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
        
    }
    func resumeTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchresults[indexPath.row]
            resumeDownload(track)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }
    func cancelTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchresults[indexPath.row]
            cacelDownload(track: track)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }
    func downloadTapped(cell: TrackCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let tracke = searchresults[indexPath.row]
            startDownload(tracke)
            tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
        }
    }
}
