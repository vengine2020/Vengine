pragma solidity >=0.4.23 <0.6.0;

contract MySmartVengine {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX6Levels;
        
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X6) x6Matrix;
 
    }
    
    struct X3 {
        address currentReferrer;
        address[] referrals;
        mapping(uint => address[]) referralsHistory;
        mapping(uint => address) currentReferrerHistory;
        bool blocked;
        uint reinvestCount;
        mapping(uint => address) reinvestX3Info;
    }
    
    struct X6 {
        address currentReferrer;
        mapping(uint => address) currentReferrerHistory;
        address[] firstLevelReferrals;
        mapping(uint => address[]) firstLevelReferralsHistory;
        address[] secondLevelReferrals;
        mapping(uint => address[]) secondLevelReferrerHistory;
        mapping(uint => address[]) secondLevelCurrentHistory;
        mapping(uint => uint[]) secondLevelNumHistory;
        bool blocked;
        uint reinvestCount;
        mapping(uint => address) reinvestX6Info;
        address closedPart;
    }
    
    struct X62 {
        address referrer;
        address current;
        uint num;
        bool blocked;
    }

    uint8 public constant LAST_LEVEL = 12;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    

    uint public lastUserId = 2;
    
    
    uint public resonanceRate = 7000;
    
    address public owner;

    address public contractOwner = 0x0000000000000000000000000000000000000000;
    
    address public feeGetor = 0x0000000000000000000000000000000000000000;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    event SentETHDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level,uint256 quantity);
    
    
    function initPrice(uint rate) public{
        require(msg.sender == contractOwner, "No permission");
        resonanceRate = rate;
        levelPrice[1] = 100000000*5/1000*resonanceRate;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
    }
    
    constructor() public {
        address ownerAddress  = 0x0000000000000000000000000000000000000000;
        
        
        levelPrice[1] = 100000000*5/1000*resonanceRate;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 j = 1; j <= LAST_LEVEL; j++) {
            users[ownerAddress].activeX3Levels[j] = true;
            users[ownerAddress].activeX6Levels[j] = true;
        }
        
        
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }
    
    function buyNewLevel(uint8 matrix, uint8 level) external payable {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (matrix == 1) {
            
            
            uint x3ReinvestCount1 = users[msg.sender].x3Matrix[1].reinvestCount;
            uint x3ReinvestCount2 = 0;
            if(users[msg.sender].activeX3Levels[level-1]){
                x3ReinvestCount2 = users[msg.sender].x3Matrix[level-1].reinvestCount;
            }
                
            if(level == 2){
                require(x3ReinvestCount1 > 1, "cannot got up condiction");
            }else if(level == 3){
                require(x3ReinvestCount1 > 3 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }else if(level == 4){
                require(x3ReinvestCount1 > 5 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }else if(level == 5){
                require(x3ReinvestCount1 > 7 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }else if(level == 6){
                require(x3ReinvestCount1 > 9 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }else if(level == 7){
                require(x3ReinvestCount1 > 11 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }else if(level == 8){
                require(x3ReinvestCount1 > 13 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }else if(level == 9){
                require(x3ReinvestCount1 > 15 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }else if(level == 10){
                require(x3ReinvestCount1 > 17 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }else if(level == 11){
                require(x3ReinvestCount1 > 19 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }else if(level == 12){
                require(x3ReinvestCount1 > 21 || x3ReinvestCount2 > 1, "cannot got up condiction");
            }
            
            require(!users[msg.sender].activeX3Levels[level], "level already activated");

            if(users[msg.sender].activeX3Levels[level-1]){
                if (users[msg.sender].x3Matrix[level-1].blocked) {
                    users[msg.sender].x3Matrix[level-1].blocked = false;
                }
            }
            
    
            address freeX3Referrer = findFreeX3Referrer(msg.sender, level);
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            updateX3Referrer(msg.sender, freeX3Referrer, level);
            
            emit Upgrade(msg.sender, freeX3Referrer, 1, level);

        } else {
            
            
            require(users[msg.sender].activeX3Levels[level], "last level not active");
             
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            if(users[msg.sender].activeX6Levels[level-1]){
                if (users[msg.sender].x6Matrix[level-1].blocked) {
                     users[msg.sender].x6Matrix[level-1].blocked = false;
                 }
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
    }    
    
    function registration(address userAddress, address referrerAddress) private {
        
        require(msg.value == levelPrice[1]*2, "registration cost 10");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activeX3Levels[1] = true; 
        users[userAddress].activeX6Levels[1] = true;
        
        
        
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeX3Referrer(userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        updateX3Referrer(userAddress, freeX3Referrer, 1);

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateX3Referrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);
        
        
        users[referrerAddress].x3Matrix[level].referralsHistory[users[referrerAddress].x3Matrix[level].reinvestCount].push(userAddress);
        
        users[userAddress].x3Matrix[level].currentReferrerHistory[users[userAddress].x3Matrix[level].reinvestCount] = referrerAddress;

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].x3Matrix[level].referrals.length));
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }
        
        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        
        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (!users[referrerAddress].activeX3Levels[level+1] && level != LAST_LEVEL && users[referrerAddress].x3Matrix[level].reinvestCount >= 2) {
            
            users[referrerAddress].x3Matrix[level].blocked = true;
        }

        
        if (referrerAddress != owner) {
            
            address freeReferrerAddress = findFreeX3Referrer(referrerAddress, level);
            if (users[referrerAddress].x3Matrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].x3Matrix[level].currentReferrer = freeReferrerAddress;
            }
            
            users[referrerAddress].x3Matrix[level].reinvestX3Info[users[referrerAddress].x3Matrix[level].reinvestCount] = userAddress;
            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateX3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[referrerAddress].x3Matrix[level].reinvestX3Info[users[referrerAddress].x3Matrix[level].reinvestCount] = userAddress;
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            
            users[referrerAddress].x6Matrix[level].firstLevelReferralsHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;
            
            users[userAddress].x6Matrix[level].currentReferrerHistory[users[userAddress].x6Matrix[level].reinvestCount] = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress);
            
            
            X62 memory secondLevelX6 = X62({
                referrer: referrerAddress,
                current: userAddress,
                num:4,
                blocked: users[ref].x6Matrix[level].blocked
            }); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    secondLevelX6.num = 5;
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    secondLevelX6.num = 6;
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    secondLevelX6.num = 3;
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    secondLevelX6.num = 4;
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    secondLevelX6.num = 5;
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    secondLevelX6.num = 6;
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }
            users[ref].x6Matrix[level].secondLevelReferrerHistory[users[ref].x6Matrix[level].reinvestCount].push(secondLevelX6.referrer);
            users[ref].x6Matrix[level].secondLevelCurrentHistory[users[ref].x6Matrix[level].reinvestCount].push(secondLevelX6.current);
            users[ref].x6Matrix[level].secondLevelNumHistory[users[ref].x6Matrix[level].reinvestCount].push(secondLevelX6.num);

            return updateX6ReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);
        
        X62 memory secondLevelX6 = X62({
            referrer: referrerAddress,
            current: userAddress,
            num:4,
            blocked: users[referrerAddress].x6Matrix[level].blocked
        });

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                (secondLevelX6.num,secondLevelX6.referrer) = updateX6(userAddress, referrerAddress, level, true);
                users[referrerAddress].x6Matrix[level].secondLevelReferrerHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.referrer);
                users[referrerAddress].x6Matrix[level].secondLevelCurrentHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.current);
                users[referrerAddress].x6Matrix[level].secondLevelNumHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.num);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                (secondLevelX6.num,secondLevelX6.referrer) = updateX6(userAddress, referrerAddress, level, true);
                users[referrerAddress].x6Matrix[level].secondLevelReferrerHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.referrer);
                users[referrerAddress].x6Matrix[level].secondLevelCurrentHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.current);
                users[referrerAddress].x6Matrix[level].secondLevelNumHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.num);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                (secondLevelX6.num,secondLevelX6.referrer) = updateX6(userAddress, referrerAddress, level, false);
                users[referrerAddress].x6Matrix[level].secondLevelReferrerHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.referrer);
                users[referrerAddress].x6Matrix[level].secondLevelCurrentHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.current);
                users[referrerAddress].x6Matrix[level].secondLevelNumHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.num);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            (secondLevelX6.num,secondLevelX6.referrer) = updateX6(userAddress, referrerAddress, level, false);
            users[referrerAddress].x6Matrix[level].secondLevelReferrerHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.referrer);
            users[referrerAddress].x6Matrix[level].secondLevelCurrentHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.current);
            users[referrerAddress].x6Matrix[level].secondLevelNumHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.num);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            (secondLevelX6.num,secondLevelX6.referrer) = updateX6(userAddress, referrerAddress, level, true);
            users[referrerAddress].x6Matrix[level].secondLevelReferrerHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.referrer);
            users[referrerAddress].x6Matrix[level].secondLevelCurrentHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.current);
            users[referrerAddress].x6Matrix[level].secondLevelNumHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.num);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            (secondLevelX6.num,secondLevelX6.referrer) = updateX6(userAddress, referrerAddress, level, false);
            users[referrerAddress].x6Matrix[level].secondLevelReferrerHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.referrer);
            users[referrerAddress].x6Matrix[level].secondLevelCurrentHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.current);
            users[referrerAddress].x6Matrix[level].secondLevelNumHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.num);
        } else {
            (secondLevelX6.num,secondLevelX6.referrer) = updateX6(userAddress, referrerAddress, level, true);
            users[referrerAddress].x6Matrix[level].secondLevelReferrerHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.referrer);
            users[referrerAddress].x6Matrix[level].secondLevelCurrentHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.current);
            users[referrerAddress].x6Matrix[level].secondLevelNumHistory[users[referrerAddress].x6Matrix[level].reinvestCount].push(secondLevelX6.num);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private returns(uint, address){
        uint x6num = 3;
        address x6Referrer;
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferralsHistory[users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].reinvestCount].push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            x6Referrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
            x6num = 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length);
            
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
            
            users[userAddress].x6Matrix[level].currentReferrerHistory[users[userAddress].x6Matrix[level].reinvestCount] = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];

        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferralsHistory[users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].reinvestCount].push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            x6Referrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
            x6num = 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length);
            
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
            
            users[userAddress].x6Matrix[level].currentReferrerHistory[users[userAddress].x6Matrix[level].reinvestCount] = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];

        }
        
        return (x6num,x6Referrer);
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL && users[referrerAddress].x6Matrix[level].reinvestCount >= 2) {
            users[referrerAddress].x6Matrix[level].blocked = true;
        }
        
        users[referrerAddress].x6Matrix[level].reinvestX6Info[users[referrerAddress].x6Matrix[level].reinvestCount] = userAddress;
        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }
    
    function findFreeX3Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX3Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
        
    function usersActiveX3Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX3Levels[level];
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX3Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, bool, uint256) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount);
    }
    
    function usersX3MatrixHistory(address userAddress, uint8 level, uint reinvestCount) public view returns(address, address[] memory, bool, uint256,address[] memory,address) {
        return (users[userAddress].x3Matrix[level].currentReferrer,
                users[userAddress].x3Matrix[level].referrals,
                users[userAddress].x3Matrix[level].blocked,
                users[userAddress].x3Matrix[level].reinvestCount,
                users[userAddress].x3Matrix[level].referralsHistory[reinvestCount],
                users[userAddress].x3Matrix[level].currentReferrerHistory[reinvestCount]);
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint256) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart,
                users[userAddress].x6Matrix[level].reinvestCount);
    }
    
    function usersX6MatrixHistory(address userAddress, uint8 level,uint reinvestCount) public view returns(address,address[] memory,address[] memory,address[] memory,uint[] memory) {
       
        return (
                users[userAddress].x6Matrix[level].currentReferrerHistory[reinvestCount],
                users[userAddress].x6Matrix[level].firstLevelReferralsHistory[reinvestCount],
                users[userAddress].x6Matrix[level].secondLevelReferrerHistory[reinvestCount],
                users[userAddress].x6Matrix[level].secondLevelCurrentHistory[reinvestCount],
                users[userAddress].x6Matrix[level].secondLevelNumHistory[reinvestCount]);
    }
    
    function usersReinvestInfo(address userAddress,uint8 matrix, uint8 level, uint reinvestCount) public view returns(address) {
        if(matrix == 1){
            return (users[userAddress].x3Matrix[level].reinvestX3Info[reinvestCount]);
        }else{
            return (users[userAddress].x6Matrix[level].reinvestX6Info[reinvestCount]);
        }
        
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

       
        
        uint receiverAmount = levelPrice[level]*99/100;
        uint feeGetorAmount = levelPrice[level]*1/100;
        address(uint160(receiver)).transfer(receiverAmount);
        address(uint160(feeGetor)).transfer(feeGetorAmount);

        emit SentETHDividends(_from, receiver, matrix, level,levelPrice[level]);
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}