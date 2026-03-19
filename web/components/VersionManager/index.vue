<template>
  <el-card class="version-manager">
    <template #header>
      <div class="card-header">
        <div class="left">
          <span> {{ cardHeadTitle }} </span>
          <template v-if="!brewRunning && !showNextBtn">
            <el-select v-model="libSrc" style="margin-left: 8px" :disabled="currentType.getListing">
              <el-option :disabled="!checkBrew()" value="brew" label="Homebrew"></el-option>
              <template v-if="typeFlag !== 'caddy'">
                <el-option value="port" :label="systemPackger"></el-option>
              </template>
              <template v-if="typeFlag === 'php'">
                <el-option value="static" label="static-php"></el-option>
              </template>
              <template v-else-if="typeFlag === 'caddy'">
                <el-option value="static" label="static-caddy"></el-option>
              </template>
            </el-select>
          </template>
        </div>
        <el-button v-if="showNextBtn" type="primary" @click="toNext">{{
          $t('base.confirm')
        }}</el-button>
        <el-button
          v-else
          class="button"
          :disabled="currentType.getListing || brewRunning"
          link
          @click="reGetData"
        >
          <yb-icon
            :svg="import('@/svg/icon_refresh.svg?raw')"
            class="refresh-icon"
            :class="{ 'fa-spin': currentType.getListing || brewRunning }"
          ></yb-icon>
        </el-button>
      </div>
    </template>
    <template v-if="showLog">
      <div ref="logs" class="logs"></div>
    </template>
    <el-table
      v-else
      :empty-text="$t('base.gettingVersion')"
      height="100%"
      :data="tableData"
      :border="false"
      style="width: 100%"
    >
      <el-table-column prop="name">
        <template #header>
          <span style="padding: 2px 12px 2px 24px; display: block">{{
            $t('base.brewLibrary')
          }}</span>
        </template>
        <template #="scope">
          <span style="padding: 2px 12px 2px 24px; display: block">{{ scope.row.name }}</span>
        </template>
      </el-table-column>
      <el-table-column prop="version" :label="$t('base.version')" width="150"> </el-table-column>
      <el-table-column align="center" :label="$t('base.isInstalled')" width="120">
        <template #default="scope">
          <div class="cell-status">
            <yb-icon
              v-if="scope.row.installed"
              :svg="import('@/svg/ok.svg?raw')"
              class="installed"
            ></yb-icon>
          </div>
        </template>
      </el-table-column>
      <el-table-column align="center" :label="$t('base.operation')" width="120">
        <template #default="scope">
          <el-button
            type="primary"
            link
            :style="{ opacity: scope.row.version !== undefined ? 1 : 0 }"
            :disabled="brewRunning"
            @click="handleEdit(scope.$index, scope.row)"
            >{{ scope.row.installed ? $t('base.uninstall') : $t('base.install') }}</el-button
          >
        </template>
      </el-table-column>
    </el-table>
  </el-card>
</template>

<script lang="ts" setup>
  import { computed, type ComputedRef, nextTick, reactive, ref, watch } from 'vue'
  import { brewInfo, fetchVerion, portInfo } from '../../util/Brew'
  import IPC from '../../util/IPC'
  import XTerm from '../../util/XTerm'
  import { chmod } from '@shared/file'
  import { AppStore } from '../../store/app'
  import { AppSoftInstalledItem, BrewStore } from '../../store/brew'
  import { I18nT } from '@shared/lang'
  import installedVersions from '../../util/InstalledVersions'
  import Base from '../../core/Base'
  import { MessageSuccess, MessageError } from '../../util/Element'
  import { waitTime } from '../../fn'
  const { join } = require('path')
  const { existsSync, unlinkSync, copyFileSync, readFileSync, writeFileSync } = require('fs')
  const { removeSync } = require('fs-extra')

  const props = defineProps<{
    typeFlag:
      | 'nginx'
      | 'apache'
      | 'memcached'
      | 'mysql'
      | 'mariadb'
      | 'redis'
      | 'php'
      | 'mongodb'
      | 'pure-ftpd'
      | 'postgresql'
  }>()

  const showNextBtn = ref(false)
  const logs = ref()

  const brewStore = BrewStore()
  const appStore = AppStore()

  const cardHeadTitle = computed(() => {
    return brewStore.cardHeadTitle
  })
  const brewRunning = computed(() => {
    return brewStore.brewRunning
  })
  const showInstallLog = computed(() => {
    return brewStore.showInstallLog
  })
  const log = computed(() => {
    return brewStore.log
  })
  const currentType: ComputedRef<AppSoftInstalledItem> = computed(() => {
    return brewStore?.[props.typeFlag] as any
  })

  const typeFlag = computed(() => {
    return props.typeFlag
  })
  const systemPackger = computed(() => {
    return global.Server.SystemPackger === 'apt' ? 'APT' : 'DNF'
  })

  const libSrc = computed({
    get() {
      return (
        brewStore.LibUse[props.typeFlag] ??
        (checkBrew() ? 'brew' : checkPort() ? 'port' : undefined)
      )
    },
    set(v: 'brew' | 'port' | 'static') {
      brewStore.LibUse[props.typeFlag] = v
    }
  })

  const tableData = computed(() => {
    if (!libSrc?.value) {
      return []
    }
    const arr = []
    const list = currentType.value.list?.[libSrc.value]
    for (const name in list) {
      const value = list[name]
      const nums = value.version.split('.').map((n: string, i: number) => {
        if (i > 0) {
          let num = parseInt(n)
          if (isNaN(num)) {
            return '00'
          }
          if (num < 10) {
            return `0${num}`
          }
          return num
        }
        return n
      })
      const num = parseInt(nums.join(''))
      Object.assign(value, {
        name,
        version: value.version,
        installed: value.installed,
        num,
        flag: value.flag
      })
      arr.push(value)
    }
    arr.sort((a, b) => {
      return b.num - a.num
    })
    return arr
  })
  const logLength = computed(() => {
    return log?.value?.length
  })
  const showLog = computed(() => {
    return showInstallLog?.value || showNextBtn?.value
  })

  const checkBrew = () => {
    return !!global.Server.BrewCellar
  }
  const checkPort = () => {
    return !!global.Server.MacPorts
  }

  let fetchFlag: Set<string> = new Set()
  const fetchData = (src: 'brew' | 'port' | 'static') => {
    fetchFlag.add(src)
    const currentItem = currentType.value
    const list = currentItem.list?.[src] ?? {}
    let getInfo: Promise<any>
    if (src === 'brew') {
      getInfo = brewInfo(props.typeFlag)
    } else if (src === 'port') {
      getInfo = portInfo(props.typeFlag)
    } else {
      getInfo = fetchVerion(props.typeFlag)
    }
    getInfo
      .then((res: any) => {
        for (const k in list) {
          delete list?.[k]
        }
        for (const name in res) {
          list[name] = reactive(res[name])
        }
        if (src === libSrc.value) {
          currentItem.getListing = false
        }
        fetchFlag.delete(src)
      })
      .catch(() => {
        if (src === libSrc.value) {
          currentItem.getListing = false
        }
        fetchFlag.delete(src)
      })
  }
  const getData = () => {
    const currentItem = currentType.value
    const src = libSrc?.value
    if (brewRunning?.value || !src || fetchFlag.has(src)) {
      return
    }
    const list = currentItem.list?.[src]
    if (Object.keys(list).length === 0) {
      currentItem.getListing = true
      if (props.typeFlag === 'php') {
        if (src === 'brew' && !appStore?.config?.setup?.phpBrewInited) {
          IPC.send('app-fork:brew', 'addTap', 'shivammathur/php').then((key: string, res: any) => {
            IPC.off(key)
            if (res?.data === 2) {
              appStore.config.setup.phpBrewInited = true
              appStore.saveConfig()
              fetchData('brew')
            }
          })
        } else if (src === 'port' && !appStore?.config?.setup?.phpAptInited) {
          const fn = global.Server.SystemPackger === 'apt' ? 'initPhpApt' : 'initPhpDnf'
          IPC.send('app-fork:brew', fn).then((key: string) => {
            IPC.off(key)
            appStore.config.setup.phpAptInited = true
            appStore.saveConfig()
            fetchData('port')
          })
        }
      } else if (props.typeFlag === 'mongodb') {
        if (src === 'brew') {
          IPC.send('app-fork:brew', 'addTap', 'mongodb/brew').then((key: string, res: any) => {
            IPC.off(key)
            if (res?.data === 2) {
              fetchData('brew')
            }
          })
        }
      }
      fetchData(src)
    }
  }
  const reGetData = () => {
    if (!libSrc?.value) {
      return
    }
    const list = currentType.value.list?.[libSrc.value]
    for (let k in list) {
      delete list[k]
    }
    getData()
  }

  const handleEdit = (index: number, row: any) => {
    if (brewRunning?.value) {
      return
    }
    brewStore.log.splice(0)
    brewStore.showInstallLog = true
    brewStore.brewRunning = true
    if (row.installed) {
      brewStore.cardHeadTitle = `${I18nT('base.uninstall')} ${row.name}`
    } else {
      brewStore.cardHeadTitle = `${I18nT('base.install')} ${row.name}`
    }

    waitTime().then(() => {
      brewStore.brewRunning = false
      showNextBtn.value = true
      brewStore.showInstallLog = false
      currentType.value.installedInited = false
      reGetData()
    })
  }

  const toNext = () => {
    showNextBtn.value = false
    BrewStore().cardHeadTitle = I18nT('base.currentVersionLib')
  }

  watch(libSrc, (v) => {
    if (v) {
      reGetData()
    }
  })

  watch(brewRunning, (val) => {
    if (!val) {
      getData()
    }
  })
  watch(
    () => props.typeFlag,
    () => {
      reGetData()
    }
  )
  watch(logLength, () => {
    if (showInstallLog?.value) {
      nextTick(() => {
        let container: HTMLElement = logs?.value as any
        if (container) {
          container.scrollTop = container.scrollHeight
        }
      })
    }
  })

  getData()
  if (!brewRunning?.value) {
    brewStore.cardHeadTitle = I18nT('base.currentVersionLib')
  }
</script>
