const UIState = {
    isOpen: false,
    currentScreen: 'main',
    playerData: null,
    availableJobs: [],
    selectedJob: null,
    currentJobData: null,
    garageData: null
};

function showMainMenu() {
    hideAllScreens();
    if (UIState.mode === 'dirty') {
        document.getElementById('dirtyMainMenu').classList.add('active');
        UIState.currentScreen = 'dirtyMain';
    } else {
        document.getElementById('mainMenu').classList.add('active');
        UIState.currentScreen = 'main';
    }
}

function showDirtyMainMenu() {
    hideAllScreens();
    document.getElementById('dirtyMainMenu').classList.add('active');
    UIState.currentScreen = 'dirtyMain';
}

function showJobSelection() {
    hideAllScreens();
    UIState.currentScreen = 'jobs';
    UIState.jobCategory = 'legit';
    document.getElementById('jobSelection').classList.add('active');
    document.getElementById('jobSelectionTitle').textContent = '📋 Legit Jobs';
    requestJobsForCategory('legit');
}

function showDirtyJobs() {
    hideAllScreens();
    UIState.currentScreen = 'jobs';
    UIState.jobCategory = 'dirty';
    document.getElementById('jobSelection').classList.add('active');
    document.getElementById('jobSelectionTitle').textContent = '💀 Dirty Jobs (Black Money)';
    requestJobsForCategory('dirty');
}

function requestJobsForCategory(category) {
    document.getElementById('jobList').innerHTML = '<p class="loading-text">Loading jobs...</p>';
    postNui('requestAvailableJobs', { category: category }).catch(() => {});
}

function showJobDetails(jobType) {
    const jobConfig = UIState.availableJobs.find(j => j.id === jobType);
    if (!jobConfig) return;

    UIState.selectedJob = jobType;
    hideAllScreens();
    
    document.getElementById('jobName').textContent = jobConfig.name;
    document.getElementById('detailJobType').textContent = jobConfig.name;
    document.getElementById('detailBasePay').textContent = '$' + jobConfig.basePay;
    document.getElementById('detailXPReward').textContent = jobConfig.xpReward + ' XP';
    
    const requirements = [
        'Drive to the depot',
        'Spawn a company truck',
        'Attach a trailer',
        'Drive to destination',
        'Deliver cargo'
    ];
    
    document.getElementById('detailRequirements').innerHTML = 
        requirements.map(r => `<li>${r}</li>`).join('');
    
    document.getElementById('jobDetails').classList.add('active');
    UIState.currentScreen = 'jobDetails';
}

function showGarage() {
    hideAllScreens();
    document.getElementById('garage').classList.add('active');
    UIState.currentScreen = 'garage';
    requestGarageData();
}

function showStats() {
    hideAllScreens();
    document.getElementById('statsScreen').classList.add('active');
    UIState.currentScreen = 'stats';
    updateStatsDisplay();
}

function showLeaderboard() {
    hideAllScreens();
    document.getElementById('leaderboardScreen').classList.add('active');
    UIState.currentScreen = 'leaderboard';
    UIState.leaderboardSort = UIState.leaderboardSort || 'xp';
    requestLeaderboard(UIState.leaderboardSort);
}

function showAchievements() {
    hideAllScreens();
    document.getElementById('achievementsScreen').classList.add('active');
    UIState.currentScreen = 'achievements';
    document.getElementById('achievementsList').innerHTML = '<p class="loading-text">Loading achievements...</p>';
    postNui('requestAchievements', {}).catch(() => {});
}

function renderAchievements(list) {
    const el = document.getElementById('achievementsList');
    if (!el) return;
    if (!list || list.length === 0) {
        el.innerHTML = '<p>No achievements configured.</p>';
        return;
    }
    const unlocked = list.filter(a => a.unlocked).length;
    el.innerHTML =
        `<div class="ach-progress">${unlocked} / ${list.length} unlocked</div>` +
        list.map(a => {
            const cls = 'ach-card' + (a.unlocked ? ' unlocked' : ' locked');
            const reward = a.reward && (a.reward.xp || a.reward.cash)
                ? `<div class="ach-reward">${a.reward.xp ? '+' + a.reward.xp + ' XP' : ''} ${a.reward.cash ? '$' + a.reward.cash : ''}</div>`
                : '';
            return `
            <div class="${cls}">
                <div class="ach-icon">${a.icon || '🏆'}</div>
                <div class="ach-body">
                    <div class="ach-name">${a.name}</div>
                    <div class="ach-desc">${a.description}</div>
                    ${reward}
                </div>
                <div class="ach-status">${a.unlocked ? '✓' : '🔒'}</div>
            </div>`;
        }).join('');
}

function showPerks() {
    hideAllScreens();
    document.getElementById('perksScreen').classList.add('active');
    UIState.currentScreen = 'perks';
    document.getElementById('perksList').innerHTML = '<p class="loading-text">Loading perks...</p>';
    postNui('requestPerks', {}).catch(() => {});
}

function renderPerks(payload) {
    if (!payload) return;
    const pts = payload.points || { available: 0, spent: 0 };
    document.getElementById('perksPoints').innerHTML =
        `<strong>${pts.available}</strong> points available <span style="color:#6b7280">(${pts.spent} spent)</span>`;

    const list = payload.perks || [];
    const el = document.getElementById('perksList');
    if (!list.length) { el.innerHTML = '<p>No perks available.</p>'; return; }

    el.innerHTML = list.map(p => {
        const maxed = p.rank >= p.max_rank;
        const canBuy = !maxed && pts.available >= (p.cost || 1);
        const eff = p.effect ? `+${Math.round((p.effect.value || 0) * 100)}% ${p.effect.type.replace(/_/g,' ')} per rank` : '';
        return `
        <div class="perk-card${maxed ? ' maxed' : ''}">
            <div class="perk-icon">${p.icon || '✨'}</div>
            <div class="perk-body">
                <div class="perk-name">${p.name}</div>
                <div class="perk-desc">${p.desc}</div>
                <div class="perk-effect">${eff}</div>
                <div class="perk-rank">Rank ${p.rank} / ${p.max_rank}</div>
            </div>
            <button class="btn ${canBuy ? 'btn-primary' : 'btn-disabled'}"
                    ${canBuy ? '' : 'disabled'}
                    onclick="rankUpPerk('${p.id}')">
                ${maxed ? 'MAX' : `Buy (${p.cost || 1})`}
            </button>
        </div>`;
    }).join('');
}

function rankUpPerk(perkId) {
    postNui('rankUpPerk', { perkId: perkId }).catch(() => {});
}


function showAchievementToast(ach) {
    if (!ach) return;
    const t = document.createElement('div');
    t.className = 'achievement-toast';
    t.innerHTML = `
        <div class="at-icon">${ach.icon || '🏆'}</div>
        <div class="at-body">
            <div class="at-title">Achievement Unlocked</div>
            <div class="at-name">${ach.name}</div>
        </div>
    `;
    document.body.appendChild(t);
    requestAnimationFrame(() => t.classList.add('show'));
    setTimeout(() => {
        t.classList.remove('show');
        setTimeout(() => t.remove(), 400);
    }, 4500);
}

function switchLeaderboardTab(sortBy) {
    UIState.leaderboardSort = sortBy;
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');
    requestLeaderboard(sortBy);
}

function requestLeaderboard(sortBy) {
    document.getElementById('leaderboardList').innerHTML = '<p class="loading-text">Loading leaderboard...</p>';
    postNui('getLeaderboard', { sortBy: sortBy })
        .then(data => renderLeaderboard(data || [], sortBy))
        .catch(() => {
            document.getElementById('leaderboardList').innerHTML = '<p class="loading-text">Failed to load leaderboard.</p>';
        });
}

function renderLeaderboard(rows, sortBy) {
    const list = document.getElementById('leaderboardList');
    if (!rows || rows.length === 0) {
        list.innerHTML = '<p class="loading-text">No truckers on the leaderboard yet.</p>';
        return;
    }

    const formatValue = (row) => {
        switch (sortBy) {
            case 'jobs':     return (row.jobs_completed || 0) + ' jobs';
            case 'money':    return '$' + (row.money_earned || 0).toLocaleString();
            case 'distance': return ((row.distance_traveled || 0) / 1000).toFixed(1) + ' km';
            case 'xp':
            default:         return 'Lvl ' + (row.level || 1) + ' (' + (row.total_xp || 0) + ' XP)';
        }
    };

    list.innerHTML = rows.map((row, i) => {
        const rank = i + 1;
        const rankClass = rank <= 3 ? ' rank-' + rank : '';
        const meClass = row.is_me ? ' is-me' : '';
        return `
            <div class="lb-row${rankClass}${meClass}">
                <span class="lb-rank">#${rank}</span>
                <span class="lb-name">${row.name || 'Unknown'}</span>
                <span class="lb-value">${formatValue(row)}</span>
            </div>
        `;
    }).join('');
}

function hideAllScreens() {
    document.querySelectorAll('.menu-screen').forEach(screen => {
        screen.classList.remove('active');
    });
}

function updatePlayerDisplay() {
    if (!UIState.playerData) return;

    const level = UIState.playerData.level || 1;
    const xp = UIState.playerData.xp || 0;
    const totalXP = UIState.playerData.total_xp || 0;
    const nextLevelXP = (level + 1) * 1000;
    const xpPercent = Math.min(100, (xp / nextLevelXP) * 100);

    document.getElementById('displayLevel').textContent = level;
    document.getElementById('xpProgress').style.width = xpPercent + '%';
    document.getElementById('xpText').textContent = xp + ' / ' + nextLevelXP;
    document.getElementById('totalEarnings').textContent = '$' + (UIState.playerData.money_earned || 0);
}

function updateStatsDisplay() {
    if (!UIState.playerData) return;

    document.getElementById('statLevel').textContent = UIState.playerData.level || 1;
    document.getElementById('statTotalXP').textContent = (UIState.playerData.total_xp || 0) + ' XP';
    document.getElementById('statJobsCompleted').textContent = UIState.playerData.jobs_completed || 0;
    
    const distance = (UIState.playerData.distance_traveled || 0) / 1000;
    document.getElementById('statDistance').textContent = distance.toFixed(2) + ' km';
    document.getElementById('statTotalEarnings').textContent = '$' + (UIState.playerData.money_earned || 0);

    const skills = UIState.playerData.skills || {};
    updateSkillDisplay('distance_driving', skills.distance_driving);
    updateSkillDisplay('fragile_handling', skills.fragile_handling);
    updateSkillDisplay('speed_efficiency', skills.speed_efficiency);
}

function updateSkillDisplay(skillName, value) {
    const displayName = skillName.replace(/_/g, ' ');
    const element = document.getElementById('skill' + skillName.replace(/_/g, ''));
    const textElement = document.getElementById('skill' + skillName.replace(/_/g, '') + 'Text');
    
    if (element) {
        const percent = Math.min(100, (value / 100) * 100);
        element.style.width = percent + '%';
    }
    if (textElement) {
        textElement.textContent = value || 0;
    }
}

function populateJobList() {
    renderJobList();
}

function renderJobList() {
    const listEl = document.getElementById('jobList');
    if (!listEl) return;

    if (!UIState.availableJobs || UIState.availableJobs.length === 0) {
        listEl.innerHTML = '<p>No jobs available yet. Level up to unlock more!</p>';
        return;
    }

    const searchEl = document.getElementById('jobSearch');
    const sortEl = document.getElementById('jobSort');
    const query = (searchEl && searchEl.value || '').trim().toLowerCase();
    const sortMode = (sortEl && sortEl.value) || 'payHigh';

    let jobs = UIState.availableJobs.slice();

    if (query) {
        jobs = jobs.filter(j =>
            (j.name || '').toLowerCase().includes(query) ||
            (j.description || '').toLowerCase().includes(query)
        );
    }

    jobs.sort((a, b) => {
        switch (sortMode) {
            case 'payLow':  return (a.basePay || 0) - (b.basePay || 0);
            case 'xpHigh':  return (b.xpReward || 0) - (a.xpReward || 0);
            case 'nameAZ':  return (a.name || '').localeCompare(b.name || '');
            case 'payHigh':
            default:        return (b.basePay || 0) - (a.basePay || 0);
        }
    });

    if (jobs.length === 0) {
        listEl.innerHTML = '<p>No jobs match your filter.</p>';
        return;
    }

    listEl.innerHTML = jobs.map(job => {
        const dirtyTag = job.isDirty ? '<span style="color:#ef4444; font-size:11px; font-weight:bold; margin-left:8px;">💀 BLACK MONEY</span>' : '';
        const payLabel = job.isDirty ? 'Dirty Pay' : 'Base Pay';
        const cardClass = job.isDirty ? 'job-card dirty-job' : 'job-card';
        return `
        <div class="${cardClass}" onclick="showJobDetails('${job.id}')">
            <h3 class="job-title">${job.name}${dirtyTag}</h3>
            <p class="job-description">${job.description}</p>
            <div class="job-info">
                <div class="job-info-item">
                    <span class="job-info-label">${payLabel}</span>
                    <span class="job-info-value">$${job.basePay}</span>
                </div>
                <div class="job-info-item">
                    <span class="job-info-label">XP Reward</span>
                    <span class="job-info-value">${job.xpReward}</span>
                </div>
            </div>
            <button class="btn ${job.isDirty ? 'btn-danger' : 'btn-primary'}">Select Job</button>
        </div>
        `;
    }).join('');
}

function populateGarage() {
    if (!UIState.garageData) {
        document.getElementById('ownedVehicles').innerHTML = '<p>Loading trucks...</p>';
        document.getElementById('purchasableVehicles').innerHTML = '';
        return;
    }

    const companyTrucks = UIState.garageData.companyTrucks || [];
    const purchasable = UIState.garageData.purchasable || [];
    const hasActiveJob = UIState.garageData.hasActiveJob === true;

    const ownedHTML = companyTrucks.map((truck, index) => `
        <div class="vehicle-card">
            <h3 class="vehicle-name">${truck.name}</h3>
            <p class="vehicle-specs">Model: ${truck.model} | Fuel: ${truck.fuel}% | Condition: ${truck.condition}%</p>
            <p class="vehicle-specs">Trailer: ${truck.trailer}</p>
            <button class="btn btn-primary" onclick="spawnCompanyTruck(${index + 1})" ${hasActiveJob ? '' : 'disabled'}>
                Spawn Truck
            </button>
            <button class="btn btn-secondary" onclick="spawnTrailer(${index + 1})" ${hasActiveJob ? '' : 'disabled'}>
                Spawn Trailer
            </button>
        </div>
    `).join('');

    document.getElementById('ownedVehicles').innerHTML = ownedHTML || '<p>No company trucks configured.</p>';

    const purchasableHTML = purchasable.map(truck => `
        <div class="vehicle-card">
            <h3 class="vehicle-name">${truck.name}</h3>
            <p class="vehicle-price">$${truck.price.toLocaleString()}</p>
            <p class="vehicle-specs">Model: ${truck.model} | Fuel Cap: ${truck.fuel_capacity}L</p>
            <p class="vehicle-specs">Consumption: ${truck.fuel_consumption} L/km</p>
        </div>
    `).join('');

    document.getElementById('purchasableVehicles').innerHTML = purchasableHTML || '<p>No purchasable trucks configured.</p>';
}

function requestGarageData() {
    postNui('getGarageData')
        .then(data => {
            UIState.garageData = data;
            populateGarage();
        })
        .catch(() => {
            document.getElementById('ownedVehicles').innerHTML = '<p>Unable to load garage data.</p>';
        });
}

function postNui(endpoint, payload) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload || {})
    })
        .then(response => response.text())
        .then(text => {
            if (!text) return {};

            try {
                return JSON.parse(text);
            } catch {
                return {};
            }
        });
}

function spawnCompanyTruck(truckIndex) {
    postNui('spawnCompanyTruck', { truckIndex })
        .then(result => {
            if (result.success) {
                closeUI();
            }
        })
        .catch(() => {
            showNotification('Trucking', 'Unable to spawn truck right now.', 'error');
        });
}

function spawnTrailer(truckIndex) {
    postNui('spawnTrailer', { truckIndex })
        .then(result => {
            if (result.success) {
                closeUI();
            }
        })
        .catch(() => {
            showNotification('Trucking', 'Unable to spawn trailer right now.', 'error');
        });
}

function acceptJob() {
    if (!UIState.selectedJob) return;

    postNui('acceptJob', { jobType: UIState.selectedJob })
        .then(() => {
            closeUI();
        })
        .catch(() => {
            showNotification('Trucking', 'Unable to accept that job right now.', 'error');
        });
}

function attachTrailer() {
    postNui('attachTrailer').catch(() => {
        showNotification('Trucking', 'Unable to attach trailer right now.', 'error');
    });
}

function detachTrailer() {
    postNui('detachTrailer').catch(() => {
        showNotification('Trucking', 'Unable to detach trailer right now.', 'error');
    });
}

function cancelJobUI() {
    postNui('cancelJob')
        .then(() => {
            closeUI();
        })
        .catch(() => {
            showNotification('Trucking', 'Unable to cancel the job right now.', 'error');
        });
}

function openUI(mode) {
    if (UIState.isOpen) return;
    
    UIState.isOpen = true;
    UIState.mode = mode || 'legit';
    document.querySelector('.app-container').style.display = 'flex';
    
    if (UIState.mode === 'dirty') {
        showDirtyMainMenu();
    } else {
        showMainMenu();
    }
    
    postNui('getPlayerData')
        .then(data => {
            if (data && Object.keys(data).length > 0) {
                UIState.playerData = data;
                updatePlayerDisplay();
                updateStatsDisplay();
            }
        })
        .catch(() => {});
}

function closeUI() {
    UIState.isOpen = false;
    document.querySelector('.app-container').style.display = 'none';
    
    postNui('uiClosed').catch(() => {});
}

function toggleUI() {
    if (UIState.isOpen) {
        closeUI();
    } else {
        openUI();
    }
}

const HUD = {
    visible: localStorage.getItem('truckingHudVisible') !== 'false',
    el: () => document.getElementById('truckingHUD')
};

function setHudVisible(visible) {
    HUD.visible = !!visible;
    localStorage.setItem('truckingHudVisible', HUD.visible ? 'true' : 'false');
    const el = HUD.el();
    if (el) el.classList.toggle('hidden', !HUD.visible);
}

function toggleHud() { setHudVisible(!HUD.visible); }

function updateJobHUD(jobData) {
    const el = HUD.el();
    if (!el) return;
    if (!jobData || !jobData.active) {
        el.classList.add('hidden');
        return;
    }
    el.classList.toggle('hidden', !HUD.visible);
    el.classList.toggle('dirty', !!jobData.isDirty);

    const setText = (id, val) => {
        const e = document.getElementById(id);
        if (e) e.textContent = val;
    };
    setText('thudJobName', jobData.name || (jobData.isDirty ? 'Dirty Run' : 'Delivery'));
    setText('thudSpeed',   Math.round(jobData.speedMph || 0));
    if (jobData.distance != null) {
        const d = jobData.distance;
        setText('thudDist', d >= 1000 ? (d / 1000).toFixed(1) + ' km' : Math.round(d));
        const distEl = document.getElementById('thudDist');
        if (distEl) distEl.parentElement.querySelector('.thud-unit') &&
            (distEl.parentElement.querySelector('.thud-unit').textContent = d >= 1000 ? '' : 'm');
    }
    setText('thudPay', '$' + (jobData.payment || 0));
    setText('thudXP', (jobData.xp || 0) + ' XP');
}

function updateVehicleHUD(fuel, engine, damage) {
    const fuelEl = document.getElementById('thudFuel');
    const engEl  = document.getElementById('thudEngine');
    if (fuelEl) {
        fuelEl.style.width = Math.max(0, Math.min(100, fuel || 0)) + '%';
        fuelEl.className = 'thud-meter-fill ' + (fuel < 15 ? 'critical' : fuel < 30 ? 'low' : 'fuel');
    }
    if (engEl) {
        engEl.style.width = Math.max(0, Math.min(100, engine || 0)) + '%';
        engEl.className = 'thud-meter-fill ' + (engine < 20 ? 'critical' : engine < 50 ? 'low' : 'engine');
    }
}

function updateTrailerStatus(attached) {
    const el = document.getElementById('thudTrailer');
    if (el) {
        el.textContent = 'Trailer: ' + (attached ? '✓ Attached' : '✗ Not attached');
        el.style.color = attached ? '#34d399' : '#fca5a5';
    }
}

document.addEventListener('DOMContentLoaded', () => setHudVisible(HUD.visible));

function updateCriminalDisplay(data) {
    if (!data) return;
    const set = (id, v) => { const e = document.getElementById(id); if (e) e.textContent = v; };
    set('crimRank',  data.rank || 'Street Runner');
    set('crimLevel', data.level || 1);
    set('crimJobsDone', data.jobs || 0);

    const rep = data.rep || 0;
    const need = data.nextLevelRep || 750;
    const pct = Math.min(100, Math.round((rep / need) * 100));
    const fill = document.getElementById('crimRepFill');
    if (fill) fill.style.width = pct + '%';
    set('crimRepText', rep + ' / ' + need);
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        toggleUI();
    }

    if (UIState.isOpen) {
        if (event.key === '1') showMainMenu();
        if (event.key === '2') showJobSelection();
        if (event.key === '3') showGarage();
        if (event.key === '4') showStats();
    }
});

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.type === 'openUI') {
        openUI(data.mode);
    }

    if (data.type === 'updatePlayerData') {
        UIState.playerData = data.data;
        updatePlayerDisplay();
        updateStatsDisplay();
    }

    if (data.type === 'updateAvailableJobs') {
        UIState.availableJobs = data.jobs;
        if (UIState.currentScreen === 'jobs') {
            populateJobList();
        }
    }

    if (data.type === 'updateJobHUD') {
        updateJobHUD(data.jobData);
    }

    if (data.type === 'updatePerks') {
        renderPerks(data.data);
    }

    if (data.type === 'updateVehicleHUD') {
        updateVehicleHUD(data.fuel, data.engine, data.damage);
    }

    if (data.type === 'updateTrailerStatus') {
        updateTrailerStatus(data.attached);
    }

    if (data.type === 'setHudVisible') {
        setHudVisible(data.visible);
    }

    if (data.type === 'updateCriminalData') {
        updateCriminalDisplay(data.data);
    }

    if (data.type === 'updateAchievements') {
        renderAchievements(data.list);
    }

    if (data.type === 'closeUI') {
        closeUI();
    }

    if (data.type === 'showNotification') {
        showNotification(data.title, data.message, data.notificationType);
    }
});


document.addEventListener('DOMContentLoaded', function() {
    document.querySelector('.app-container').style.display = 'none';
});

// For testing - uncomment to test UI locally
// window.addEventListener('load', function() {
//     UIState.playerData = {
//         level: 5,
//         xp: 500,
//         total_xp: 2500,
//         money_earned: 5000,
//         jobs_completed: 15,
//         distance_traveled: 50000,
//         skills: {
//             distance_driving: 45,
//             fragile_handling: 30,
//             speed_efficiency: 60
//         }
//     };
//     UIState.availableJobs = [
//         { id: 'local_delivery', name: 'Local Delivery', description: 'Short city deliveries', basePay: 500, xpReward: 50 },
//         { id: 'long_haul', name: 'Long Haul', description: 'Cross-state deliveries', basePay: 2000, xpReward: 200 }
//     ];
//     openUI();
//     updatePlayerDisplay();
// });
