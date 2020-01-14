//
//  ViewController.swift
//  sockets-test
//
//  Created by yenz0redd on 01/09/2019.
//  Copyright © 2019 yenz0redd. All rights reserved.
//

import UIKit
import Starscream
import SnapKit

class ViewController: UIViewController {
    let socket = WebSocket(url: URL(string: "ws://localhost:8080/chat-room")!)

    let loginTextField = UITextField()
    let loginButton = UIButton(type: .system)
    let loginPanel = UIView()

    let messagesTextView = UITextView()
    let messageTextField = UITextField()
    let sendMessageButton = UIButton(type: .system)
    let messagesPanel = UIView()

    let loaderView = UIView()
    let loader = UIActivityIndicatorView()

    let disconnectButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.loginPanel)
        self.loginPanel.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.view.safeAreaLayoutGuide)
            make.bottom.equalTo(self.view.snp.centerY)
        }
        self.loginPanel.backgroundColor = .blue

        self.loginPanel.addSubview(self.loginTextField)
        self.loginTextField.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2)
        }
        self.loginTextField.backgroundColor = .orange

        self.loginPanel.addSubview(self.disconnectButton)
        self.disconnectButton.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview().inset(20)
            make.size.equalTo(30)
        }
    
        self.disconnectButton.setTitle("X", for: .normal)
        self.disconnectButton.setTitleColor(.white, for: .normal)
        self.disconnectButton.backgroundColor = .red
        self.disconnectButton.layer.cornerRadius = 10
        self.disconnectButton.addTarget(self, action: #selector(handleDisconnectButton), for: .touchUpInside)

        self.loginPanel.addSubview(self.loginButton)
        self.loginButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.loginTextField).offset(50)
            make.centerX.equalToSuperview()
            make.size.equalTo(40)
        }
        self.loginButton.backgroundColor = .orange
        self.loginButton.setTitle("Login", for: .normal)
        self.loginButton.addTarget(self, action: #selector(self.handleLoginButton), for: .touchUpInside)

        self.view.addSubview(self.messagesPanel)
        self.messagesPanel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.view.safeAreaLayoutGuide)
            make.top.equalTo(self.loginPanel.snp.bottom)
        }
        self.messagesPanel.backgroundColor = .yellow

        self.messagesPanel.addSubview(self.messagesTextView)
        self.messagesTextView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-50)
        }
        self.messagesTextView.isEditable = false
        self.messagesTextView.backgroundColor = .green

        self.messagesPanel.addSubview(self.sendMessageButton)
        self.sendMessageButton.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(10)
            make.height.equalTo(31)
            make.width.equalTo(50)
        }
        self.sendMessageButton.backgroundColor = .green
        self.sendMessageButton.setTitle("Send", for: .normal)
        self.sendMessageButton.addTarget(self, action: #selector(self.handleSendMessageButton), for: .touchUpInside)

        self.messagesPanel.addSubview(self.messageTextField)
        self.messageTextField.snp.makeConstraints { make in
            make.centerY.equalTo(self.sendMessageButton.snp.centerY)
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalTo(self.sendMessageButton.snp.leading).offset(-10)
        }
        self.messageTextField.backgroundColor = .green

        self.view.addSubview(loaderView)
        self.loaderView.frame = self.view.frame
        self.loaderView.backgroundColor = .black
        self.loaderView.alpha = 0.6

        self.loaderView.addSubview(self.loader)
        self.loader.frame.size = CGSize(width: 40, height: 40)
        self.loader.center = self.loaderView.center

        loader.hidesWhenStopped = true
        loader.style = UIActivityIndicatorView.Style.whiteLarge

        self.loaderView.isHidden = true
    }

    @objc private func handleLoginButton() {
        guard let login = self.loginTextField.text else { return }

        let jsonDict = ["login": login]
        guard let jsonObject = try? JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted) else { return }

        socket.connect()
        UIView.animate(withDuration: 0.5) {
            self.loaderView.isHidden = false
        }
        self.loader.startAnimating()

        socket.onConnect = { [weak self] in
            guard let strongSelf = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                strongSelf.loaderView.isHidden = true
                strongSelf.loader.stopAnimating()
                strongSelf.socket.write(data: jsonObject)
                strongSelf.messagesTextView.text = ""
            })
        }
        socket.onText = { text in
            DispatchQueue.main.async {
                self.messagesTextView.text.append(text)
            }
            print(text)
        }
    }

    @objc private func handleSendMessageButton() {
        guard let message = self.messageTextField.text else { return }

        let jsonDict = ["message": message]
        guard let jsonObject = try? JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted) else { return }

        self.socket.write(data: jsonObject)

        self.messageTextField.text = ""
    }

    @objc private func handleDisconnectButton() {
        self.socket.disconnect(forceTimeout: 5, closeCode: 100)
        self.loginTextField.text = ""
    }
}
