//
//  DownloadDelegate.swift
//  HalfTunes
//
//  Created by Jose on 2/11/18.
//  Copyright © 2018 appcat.com. All rights reserved.
//

import Foundation

// this delegate handles events specific to download tasks
extension SearchViewController: URLSessionDownloadDelegate
{
	// this is the only mandatory method, called when a download finishes
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
									didFinishDownloadingTo location: URL)
	{
		// source url is the temp url
		guard let sourceURL = downloadTask.originalRequest?.url else { return }
		
		// get the download object
		let download = downloadService.activeDownloads[sourceURL]
		downloadService.activeDownloads[sourceURL] = nil
	
		// helper method that generates a permanent location
		let destinationURL = localFilePath(for: sourceURL)
		print(destinationURL)
		
		let fileManager = FileManager.default
		try? fileManager.removeItem(at: destinationURL)
		do
		{ // move from temp to permanent location
			try fileManager.copyItem(at: location, to: destinationURL)
			download?.track.downloaded = true
		} catch let error
		{
			print("Could not copy file to disk: \(error.localizedDescription)")
		}
		
		if let index = download?.track.index
		{
			DispatchQueue.main.async
			{
				self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
			}
		}
	}
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
									didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
									totalBytesExpectedToWrite: Int64)
	{
		guard let url = downloadTask.originalRequest?.url,
			let download = downloadService.activeDownloads[url]  else { return }
		
		download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
		
		let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
		
		DispatchQueue.main.async
		{
			if let trackCell = self.tableView.cellForRow(at: IndexPath(row: download.track.index,
																																 section: 0)) as? TrackCell
			{
				trackCell.updateDisplay(progress: download.progress, totalSize: totalSize)
			}
		}
	}
	
}
