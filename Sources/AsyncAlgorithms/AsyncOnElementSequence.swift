//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Async Algorithms open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension AsyncSequence {
  public func onElement(perform sideEffect: @escaping @Sendable (Element) async -> Void) -> AsyncOnElementSequence<Self> {
    AsyncOnElementSequence(base: self, sideEffect: sideEffect)
  }
}

public struct AsyncOnElementSequence<Base: AsyncSequence>: AsyncSequence {
  public typealias Element = Base.Element

  public struct Iterator: AsyncIteratorProtocol {
    public typealias Element = Base.Element

    private var base: Base.AsyncIterator
    private let sideEffect: @Sendable (Element) async -> Void

    init(base: Base.AsyncIterator, sideEffect: @escaping @Sendable (Element) async -> Void) {
      self.base = base
      self.sideEffect = sideEffect
    }

    public mutating func next() async rethrows -> Base.Element? {
      guard let element = try await base.next() else {
        return nil
      }
      await sideEffect(element)
      return element
    }
  }

  private let base: Base
  private let sideEffect: @Sendable (Element) async -> Void

  init(base: Base, sideEffect: @escaping @Sendable (Element) async -> Void) {
    self.base = base
    self.sideEffect = sideEffect
  }

  public func makeAsyncIterator() -> Iterator {
    Iterator(base: base.makeAsyncIterator(), sideEffect: sideEffect)
  }
}
