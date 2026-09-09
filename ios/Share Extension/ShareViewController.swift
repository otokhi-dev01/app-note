//
//  ShareViewController.swift
//  Share Extension
//
//  Lets Telegram (and any other app) hand documents, photos, videos, and
//  links to Pii Note through the system share sheet. The plugin's base
//  class copies the shared items into the App-Group container and hands
//  them to the host app; the default `shouldAutoRedirect() == true` means
//  no extra UI shows here — the share sheet just closes and Pii Note opens
//  straight into a new note with the file already attached.
//
import receive_sharing_intent

class ShareViewController: RSIShareViewController {
}
