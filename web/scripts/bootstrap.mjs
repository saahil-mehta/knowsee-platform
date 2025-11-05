#!/usr/bin/env node

import { existsSync } from 'node:fs'
import { access, copyFile, readFile } from 'node:fs/promises'
import { spawn } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const projectRoot = path.resolve(__dirname, '..')

const envExamplePath = path.join(projectRoot, '.env.example')
const envLocalPath = path.join(projectRoot, '.env.local')
const nextBinary = path.join(projectRoot, 'node_modules', '.bin', 'next')
const requiredEnvKeys = ['NEXT_PUBLIC_API_URL']

const run = (cmd, args) =>
  new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { cwd: projectRoot, stdio: 'inherit', shell: process.platform === 'win32' })
    child.on('close', (code) => {
      if (code === 0) resolve(undefined)
      else reject(new Error(`${cmd} ${args.join(' ')} exited with code ${code}`))
    })
    child.on('error', reject)
  })

async function ensureDependencies() {
  if (existsSync(nextBinary)) {
    console.log('Dependencies already installed')
    return
  }

  console.log('Installing npm dependencies...')
  await run('npm', ['install', '--no-audit'])
}

async function ensureEnvFile() {
  try {
    await access(envLocalPath)
  } catch {
    try {
      await access(envExamplePath)
      await copyFile(envExamplePath, envLocalPath)
      console.log('Created .env.local from .env.example')
    } catch (error) {
      console.warn('Could not create .env.local automatically:', error.message)
      return
    }
  }

  try {
    const contents = await readFile(envLocalPath, 'utf8')
    const missing = requiredEnvKeys.filter((key) => !new RegExp(`^${key}=`, 'm').test(contents))
    if (missing.length > 0) {
      console.warn(`Missing env keys in .env.local: ${missing.join(', ')}`)
    }
  } catch (error) {
    console.warn('Unable to read .env.local:', error.message)
  }
}

async function main() {
  try {
    await ensureDependencies()
    await ensureEnvFile()
    console.log('Bootstrap complete.')
  } catch (error) {
    console.error('Bootstrap failed:', error.message)
    process.exitCode = 1
  }
}

await main()
