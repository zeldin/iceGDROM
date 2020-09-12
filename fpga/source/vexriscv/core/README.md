The file VexRiscv.v was generated from the SpinalHDL code in commit
775b336e of the https://github.com/SpinalHDL/VexRiscv repository,
using the following configuration:

    VexRiscvConfig(
      plugins = List(
        new IBusSimplePlugin(
          resetVector = 0l,
          cmdForkOnSecondStage = true,
          cmdForkPersistence = false,
          prediction = NONE,
          catchAccessFault = false,
          compressedGen = true
        ),
        new DBusSimplePlugin(
          catchAddressMisaligned = false,
          catchAccessFault = false,
          earlyInjection = true
        ),
        new CsrPlugin(CsrPluginConfig(
          catchIllegalAccess = false,
          mvendorid      = null,
          marchid        = null,
          mimpid         = null,
          mhartid        = null,
          misaExtensionsInit = 66,
          misaAccess     = CsrAccess.NONE,
          mtvecAccess    = CsrAccess.NONE,
          mtvecInit      = 4l,
          mepcAccess     = CsrAccess.NONE,
          mscratchGen    = true,
          mcauseAccess   = CsrAccess.READ_ONLY,
          mbadaddrAccess = CsrAccess.NONE,
          mcycleAccess   = CsrAccess.NONE,
          minstretAccess = CsrAccess.NONE,
          ecallGen       = false,
          wfiGenAsWait   = false,
          ucycleAccess   = CsrAccess.NONE,
          uinstretAccess = CsrAccess.NONE
        )),
        new DecoderSimplePlugin(
          catchIllegalInstruction = false
        ),
        new RegFilePlugin(
          regFileReadyKind = plugin.SYNC,
          rv32e = true,
          zeroBoot = false,
          x0Init = true
        ),
        new IntAluPlugin,
        new SrcPlugin(
          separatedAddSub = false,
          executeInsertion = true
        ),
        new FullBarrelShifterPlugin(earlyInjection = true),
        new HazardSimplePlugin(
          bypassExecute           = true,
          bypassMemory            = true,
          bypassWriteBack         = true,
          bypassWriteBackBuffer   = true,
          pessimisticUseSrc       = false,
          pessimisticWriteRegFile = false,
          pessimisticAddressMatch = false
        ),
        new MulDivIterativePlugin(
          genMul = true,
          genDiv = true,
          mulUnrollFactor = 2,
          divUnrollFactor = 2
        ),
        new BranchPlugin(
          earlyBranch = true,
          catchAddressMisaligned = false
        )
      )
    )
