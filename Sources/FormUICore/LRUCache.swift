//
//  LRUCache.swift
//  FormUI
//
//  Created by Jerry on 2026/11/17.
//

nonisolated public final class LRUCache<Key: Hashable & Sendable, Value: Sendable> {
    
    final class Node {
        let key: Key
        var value: Value
        weak var prev: Node?
        var next: Node?
        var onEvicted: ((Value) -> Void)?
        
        init(key: Key, value: Value, onEvicted: ((Value) -> Void)? = nil) {
            self.key = key
            self.value = value
            self.onEvicted = onEvicted
        }
    }
    
    public struct Iterator: IteratorProtocol {
        
        public typealias Element = (key: Key, value: Value)
        
        private var current: Node?
        
        init(head: Node?) {
            self.current = head
        }
        
        public mutating func next() -> Element? {
            guard let node = current else { return nil }
            let result = (key: node.key, value: node.value)
            current = node.next
            return result
        }
    }
    
    private let capacity: Int
    private var cache: [Key: Node] = [:]
    private var head: Node?
    private var tail: Node?
    
    public init(capacity: Int) {
        self.capacity = Swift.max(1, capacity)
    }
    
    public func get(_ key: Key) -> Value? {
        guard let node = cache[key] else { return nil }
        moveToHead(node)
        return node.value
    }
    
    public func remove(_ key: Key) {
        guard let node = cache[key] else { return }
        remove(node, permanently: true)
        cache[key] = nil
    }
    
    public func update(_ key: Key, value: Value) {
        guard let node = cache[key] else { return }
        node.value = value
        moveToHead(node)
    }
    
    public func set(_ key: Key, value: Value, onEvicted: ((Value) -> Void)? = nil) {
        if let node = cache[key] {
            node.value = value
            if onEvicted != nil {
                node.onEvicted = onEvicted
            }
            moveToHead(node)
        } else {
            let newNode = Node(key: key, value: value, onEvicted: onEvicted)
            cache[key] = newNode
            addToHead(newNode)
            if cache.count > capacity {
                removeTail()
            }
        }
    }
    
    public func removeAll() {
        var current = head
        while let node = current {
            node.onEvicted?(node.value)
            current = node.next
        }
        cache.removeAll()
        head = nil
        tail = nil
    }
    
    private func addToHead(_ node: Node) {
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
        if tail == nil {
            tail = node
        }
    }
    
    private func remove(_ node: Node, permanently: Bool) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if node === head {
            head = node.next
        }
        if node === tail {
            tail = node.prev
        }
        node.prev = nil
        node.next = nil
        if permanently {
            node.onEvicted?(node.value)
        }
    }
    
    private func moveToHead(_ node: Node) {
        remove(node, permanently: false)
        addToHead(node)
    }
    
    private func removeTail() {
        guard let oldTail = tail else { return }
        let key = oldTail.key
        remove(oldTail, permanently: true)
        cache.removeValue(forKey: key)
    }
    
    public subscript(_ key: Key) -> Value? {
        get {
            get(key)
        }
        set {
            if let newValue {
                set(key, value: newValue)
            } else {
                remove(key)
            }
        }
    }
}

extension LRUCache: Sequence {
    
    public typealias Element = (key: Key, value: Value)
    
    public func makeIterator() -> Iterator {
        Iterator(head: head)
    }
}
