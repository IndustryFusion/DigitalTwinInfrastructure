/**
* Copyright (c) 2023 Intel Corporation
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
'use strict'

const { assert } = require('chai')
const chai = require('chai')
global.should = chai.should()

const rewire = require('rewire')
const ToTest = rewire('../lib/jsonldUtils.js')

describe('Test loadContextFromFile', function () {
  it('Should load context from filename', function () {
    const fs = {
      readFileSync: (filename, coding) => {
        filename.should.equal('filename')
        return '["context"]'
      }
    }
    const revert = ToTest.__set__('fs', fs)
    //ToTest.__set__('process', process)
    const loadContextFromFile = ToTest.__get__('loadContextFromFile')
    const result = loadContextFromFile('filename')
    result.should.deep.equal(['context'])
    revert()
  })
})

describe('Test mergeContexts', function() {
  it('should return null with undefined contexts', function() {
    const result = ToTest.mergeContexts(undefined, undefined)
    assert(result === null)
  })
  it('should return only the global context', function() {
    const context = 'http://context'
    const result = ToTest.mergeContexts(undefined, context)
    result.should.deep.equal([context])
  })
  it('should return only the local context', function() {
    const context = [{ '@context': 'http://context' }]
    const result = ToTest.mergeContexts(context, undefined)
    result.should.deep.equal([['http://context']])
  })
  it('should merge both contexts', function() {
    const globalcontext = 'http://context2'
    const context = [{ '@context': 'http://context' }]
    const result = ToTest.mergeContexts(context, globalcontext)
    result.should.deep.equal([['http://context', 'http://context2']])
  })
  it('should merge object with string contexts', function() {
    const globalcontext = 'http://context2'
    const context = [{ '@context': { ns: 'http://context' } }]
    const result = ToTest.mergeContexts(context, globalcontext)
    result.should.deep.equal([[{ns: 'http://context'}, 'http://context2']])
  })
  it('should remove double context', function() {
    const globalcontext = 'http://context2'
    const context = [{ '@context': { ns: 'http://context' } }, {'@context': 'http://context2'}]
    const result = ToTest.mergeContexts(context, globalcontext)
    result.should.deep.equal([[{ns: 'http://context'}, 'http://context2'], ['http://context2']])
  })
})
