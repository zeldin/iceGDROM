// Generator : SpinalHDL v1.4.0    git head : ecb5a80b713566f417ea3ea061f9969e73770a7f
// Date      : 12/09/2020, 16:28:00
// Component : VexRiscv


`define AluBitwiseCtrlEnum_defaultEncoding_type [1:0]
`define AluBitwiseCtrlEnum_defaultEncoding_XOR_1 2'b00
`define AluBitwiseCtrlEnum_defaultEncoding_OR_1 2'b01
`define AluBitwiseCtrlEnum_defaultEncoding_AND_1 2'b10

`define Src2CtrlEnum_defaultEncoding_type [1:0]
`define Src2CtrlEnum_defaultEncoding_RS 2'b00
`define Src2CtrlEnum_defaultEncoding_IMI 2'b01
`define Src2CtrlEnum_defaultEncoding_IMS 2'b10
`define Src2CtrlEnum_defaultEncoding_PC 2'b11

`define ShiftCtrlEnum_defaultEncoding_type [1:0]
`define ShiftCtrlEnum_defaultEncoding_DISABLE_1 2'b00
`define ShiftCtrlEnum_defaultEncoding_SLL_1 2'b01
`define ShiftCtrlEnum_defaultEncoding_SRL_1 2'b10
`define ShiftCtrlEnum_defaultEncoding_SRA_1 2'b11

`define Src1CtrlEnum_defaultEncoding_type [1:0]
`define Src1CtrlEnum_defaultEncoding_RS 2'b00
`define Src1CtrlEnum_defaultEncoding_IMU 2'b01
`define Src1CtrlEnum_defaultEncoding_PC_INCREMENT 2'b10
`define Src1CtrlEnum_defaultEncoding_URS1 2'b11

`define BranchCtrlEnum_defaultEncoding_type [1:0]
`define BranchCtrlEnum_defaultEncoding_INC 2'b00
`define BranchCtrlEnum_defaultEncoding_B 2'b01
`define BranchCtrlEnum_defaultEncoding_JAL 2'b10
`define BranchCtrlEnum_defaultEncoding_JALR 2'b11

`define AluCtrlEnum_defaultEncoding_type [1:0]
`define AluCtrlEnum_defaultEncoding_ADD_SUB 2'b00
`define AluCtrlEnum_defaultEncoding_SLT_SLTU 2'b01
`define AluCtrlEnum_defaultEncoding_BITWISE 2'b10

`define EnvCtrlEnum_defaultEncoding_type [0:0]
`define EnvCtrlEnum_defaultEncoding_NONE 1'b0
`define EnvCtrlEnum_defaultEncoding_XRET 1'b1


module StreamFifoLowLatency (
  input               io_push_valid,
  output              io_push_ready,
  input               io_push_payload_error,
  input      [31:0]   io_push_payload_inst,
  output reg          io_pop_valid,
  input               io_pop_ready,
  output reg          io_pop_payload_error,
  output reg [31:0]   io_pop_payload_inst,
  input               io_flush,
  output     [0:0]    io_occupancy,
  input               clk,
  input               reset 
);
  wire                _zz_4_;
  wire       [0:0]    _zz_5_;
  reg                 _zz_1_;
  reg                 pushPtr_willIncrement;
  reg                 pushPtr_willClear;
  wire                pushPtr_willOverflowIfInc;
  wire                pushPtr_willOverflow;
  reg                 popPtr_willIncrement;
  reg                 popPtr_willClear;
  wire                popPtr_willOverflowIfInc;
  wire                popPtr_willOverflow;
  wire                ptrMatch;
  reg                 risingOccupancy;
  wire                empty;
  wire                full;
  wire                pushing;
  wire                popping;
  wire       [32:0]   _zz_2_;
  reg        [32:0]   _zz_3_;

  assign _zz_4_ = (! empty);
  assign _zz_5_ = _zz_2_[0 : 0];
  always @ (*) begin
    _zz_1_ = 1'b0;
    if(pushing)begin
      _zz_1_ = 1'b1;
    end
  end

  always @ (*) begin
    pushPtr_willIncrement = 1'b0;
    if(pushing)begin
      pushPtr_willIncrement = 1'b1;
    end
  end

  always @ (*) begin
    pushPtr_willClear = 1'b0;
    if(io_flush)begin
      pushPtr_willClear = 1'b1;
    end
  end

  assign pushPtr_willOverflowIfInc = 1'b1;
  assign pushPtr_willOverflow = (pushPtr_willOverflowIfInc && pushPtr_willIncrement);
  always @ (*) begin
    popPtr_willIncrement = 1'b0;
    if(popping)begin
      popPtr_willIncrement = 1'b1;
    end
  end

  always @ (*) begin
    popPtr_willClear = 1'b0;
    if(io_flush)begin
      popPtr_willClear = 1'b1;
    end
  end

  assign popPtr_willOverflowIfInc = 1'b1;
  assign popPtr_willOverflow = (popPtr_willOverflowIfInc && popPtr_willIncrement);
  assign ptrMatch = 1'b1;
  assign empty = (ptrMatch && (! risingOccupancy));
  assign full = (ptrMatch && risingOccupancy);
  assign pushing = (io_push_valid && io_push_ready);
  assign popping = (io_pop_valid && io_pop_ready);
  assign io_push_ready = (! full);
  always @ (*) begin
    if(_zz_4_)begin
      io_pop_valid = 1'b1;
    end else begin
      io_pop_valid = io_push_valid;
    end
  end

  assign _zz_2_ = _zz_3_;
  always @ (*) begin
    if(_zz_4_)begin
      io_pop_payload_error = _zz_5_[0];
    end else begin
      io_pop_payload_error = io_push_payload_error;
    end
  end

  always @ (*) begin
    if(_zz_4_)begin
      io_pop_payload_inst = _zz_2_[32 : 1];
    end else begin
      io_pop_payload_inst = io_push_payload_inst;
    end
  end

  assign io_occupancy = (risingOccupancy && ptrMatch);
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      risingOccupancy <= 1'b0;
    end else begin
      if((pushing != popping))begin
        risingOccupancy <= pushing;
      end
      if(io_flush)begin
        risingOccupancy <= 1'b0;
      end
    end
  end

  always @ (posedge clk) begin
    if(_zz_1_)begin
      _zz_3_ <= {io_push_payload_inst,io_push_payload_error};
    end
  end


endmodule

module VexRiscv (
  output              iBus_cmd_valid,
  input               iBus_cmd_ready,
  output     [31:0]   iBus_cmd_payload_pc,
  input               iBus_rsp_valid,
  input               iBus_rsp_payload_error,
  input      [31:0]   iBus_rsp_payload_inst,
  input               timerInterrupt,
  input               externalInterrupt,
  input               softwareInterrupt,
  output              dBus_cmd_valid,
  input               dBus_cmd_ready,
  output              dBus_cmd_payload_wr,
  output     [31:0]   dBus_cmd_payload_address,
  output     [31:0]   dBus_cmd_payload_data,
  output     [1:0]    dBus_cmd_payload_size,
  input               dBus_rsp_ready,
  input               dBus_rsp_error,
  input      [31:0]   dBus_rsp_data,
  input               clk,
  input               reset 
);
  wire                _zz_159_;
  wire                _zz_160_;
  reg        [31:0]   _zz_161_;
  reg        [31:0]   _zz_162_;
  wire                IBusSimplePlugin_rspJoin_rspBuffer_c_io_push_ready;
  wire                IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_valid;
  wire                IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_error;
  wire       [31:0]   IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_inst;
  wire       [0:0]    IBusSimplePlugin_rspJoin_rspBuffer_c_io_occupancy;
  wire                _zz_163_;
  wire                _zz_164_;
  wire                _zz_165_;
  wire                _zz_166_;
  wire                _zz_167_;
  wire                _zz_168_;
  wire                _zz_169_;
  wire                _zz_170_;
  wire                _zz_171_;
  wire                _zz_172_;
  wire       [1:0]    _zz_173_;
  wire                _zz_174_;
  wire                _zz_175_;
  wire                _zz_176_;
  wire                _zz_177_;
  wire                _zz_178_;
  wire                _zz_179_;
  wire                _zz_180_;
  wire                _zz_181_;
  wire                _zz_182_;
  wire                _zz_183_;
  wire                _zz_184_;
  wire                _zz_185_;
  wire                _zz_186_;
  wire                _zz_187_;
  wire       [4:0]    _zz_188_;
  wire       [1:0]    _zz_189_;
  wire       [1:0]    _zz_190_;
  wire       [1:0]    _zz_191_;
  wire                _zz_192_;
  wire       [0:0]    _zz_193_;
  wire       [2:0]    _zz_194_;
  wire       [31:0]   _zz_195_;
  wire       [0:0]    _zz_196_;
  wire       [0:0]    _zz_197_;
  wire       [0:0]    _zz_198_;
  wire       [0:0]    _zz_199_;
  wire       [0:0]    _zz_200_;
  wire       [0:0]    _zz_201_;
  wire       [0:0]    _zz_202_;
  wire       [0:0]    _zz_203_;
  wire       [0:0]    _zz_204_;
  wire       [0:0]    _zz_205_;
  wire       [0:0]    _zz_206_;
  wire       [32:0]   _zz_207_;
  wire       [31:0]   _zz_208_;
  wire       [32:0]   _zz_209_;
  wire       [0:0]    _zz_210_;
  wire       [0:0]    _zz_211_;
  wire       [0:0]    _zz_212_;
  wire       [1:0]    _zz_213_;
  wire       [1:0]    _zz_214_;
  wire       [2:0]    _zz_215_;
  wire       [31:0]   _zz_216_;
  wire       [2:0]    _zz_217_;
  wire       [31:0]   _zz_218_;
  wire       [31:0]   _zz_219_;
  wire       [11:0]   _zz_220_;
  wire       [11:0]   _zz_221_;
  wire       [2:0]    _zz_222_;
  wire       [0:0]    _zz_223_;
  wire       [2:0]    _zz_224_;
  wire       [0:0]    _zz_225_;
  wire       [2:0]    _zz_226_;
  wire       [0:0]    _zz_227_;
  wire       [2:0]    _zz_228_;
  wire       [0:0]    _zz_229_;
  wire       [2:0]    _zz_230_;
  wire       [4:0]    _zz_231_;
  wire       [11:0]   _zz_232_;
  wire       [11:0]   _zz_233_;
  wire       [31:0]   _zz_234_;
  wire       [31:0]   _zz_235_;
  wire       [31:0]   _zz_236_;
  wire       [31:0]   _zz_237_;
  wire       [31:0]   _zz_238_;
  wire       [31:0]   _zz_239_;
  wire       [31:0]   _zz_240_;
  wire       [0:0]    _zz_241_;
  wire       [4:0]    _zz_242_;
  wire       [34:0]   _zz_243_;
  wire       [34:0]   _zz_244_;
  wire       [32:0]   _zz_245_;
  wire       [34:0]   _zz_246_;
  wire       [33:0]   _zz_247_;
  wire       [34:0]   _zz_248_;
  wire       [33:0]   _zz_249_;
  wire       [32:0]   _zz_250_;
  wire       [34:0]   _zz_251_;
  wire       [32:0]   _zz_252_;
  wire       [0:0]    _zz_253_;
  wire       [4:0]    _zz_254_;
  wire       [32:0]   _zz_255_;
  wire       [31:0]   _zz_256_;
  wire       [31:0]   _zz_257_;
  wire       [32:0]   _zz_258_;
  wire       [32:0]   _zz_259_;
  wire       [31:0]   _zz_260_;
  wire       [31:0]   _zz_261_;
  wire       [32:0]   _zz_262_;
  wire       [32:0]   _zz_263_;
  wire       [32:0]   _zz_264_;
  wire       [32:0]   _zz_265_;
  wire       [0:0]    _zz_266_;
  wire       [32:0]   _zz_267_;
  wire       [0:0]    _zz_268_;
  wire       [32:0]   _zz_269_;
  wire       [0:0]    _zz_270_;
  wire       [31:0]   _zz_271_;
  wire       [19:0]   _zz_272_;
  wire       [11:0]   _zz_273_;
  wire       [11:0]   _zz_274_;
  wire       [0:0]    _zz_275_;
  wire       [0:0]    _zz_276_;
  wire       [0:0]    _zz_277_;
  wire       [0:0]    _zz_278_;
  wire       [0:0]    _zz_279_;
  wire       [0:0]    _zz_280_;
  wire                _zz_281_;
  wire                _zz_282_;
  wire                _zz_283_;
  wire                _zz_284_;
  wire       [6:0]    _zz_285_;
  wire       [4:0]    _zz_286_;
  wire                _zz_287_;
  wire       [4:0]    _zz_288_;
  wire       [31:0]   _zz_289_;
  wire       [31:0]   _zz_290_;
  wire                _zz_291_;
  wire       [0:0]    _zz_292_;
  wire       [0:0]    _zz_293_;
  wire                _zz_294_;
  wire       [0:0]    _zz_295_;
  wire       [0:0]    _zz_296_;
  wire       [1:0]    _zz_297_;
  wire       [1:0]    _zz_298_;
  wire                _zz_299_;
  wire       [0:0]    _zz_300_;
  wire       [22:0]   _zz_301_;
  wire       [31:0]   _zz_302_;
  wire       [31:0]   _zz_303_;
  wire       [31:0]   _zz_304_;
  wire       [31:0]   _zz_305_;
  wire       [31:0]   _zz_306_;
  wire       [31:0]   _zz_307_;
  wire       [31:0]   _zz_308_;
  wire       [31:0]   _zz_309_;
  wire                _zz_310_;
  wire       [0:0]    _zz_311_;
  wire       [0:0]    _zz_312_;
  wire                _zz_313_;
  wire       [0:0]    _zz_314_;
  wire       [19:0]   _zz_315_;
  wire                _zz_316_;
  wire                _zz_317_;
  wire                _zz_318_;
  wire                _zz_319_;
  wire                _zz_320_;
  wire       [0:0]    _zz_321_;
  wire       [0:0]    _zz_322_;
  wire                _zz_323_;
  wire       [0:0]    _zz_324_;
  wire       [15:0]   _zz_325_;
  wire       [31:0]   _zz_326_;
  wire       [0:0]    _zz_327_;
  wire       [3:0]    _zz_328_;
  wire       [0:0]    _zz_329_;
  wire       [0:0]    _zz_330_;
  wire       [1:0]    _zz_331_;
  wire       [1:0]    _zz_332_;
  wire                _zz_333_;
  wire       [0:0]    _zz_334_;
  wire       [12:0]   _zz_335_;
  wire       [31:0]   _zz_336_;
  wire       [31:0]   _zz_337_;
  wire       [31:0]   _zz_338_;
  wire                _zz_339_;
  wire       [0:0]    _zz_340_;
  wire       [0:0]    _zz_341_;
  wire       [31:0]   _zz_342_;
  wire       [31:0]   _zz_343_;
  wire       [31:0]   _zz_344_;
  wire       [31:0]   _zz_345_;
  wire       [31:0]   _zz_346_;
  wire       [31:0]   _zz_347_;
  wire       [0:0]    _zz_348_;
  wire       [1:0]    _zz_349_;
  wire       [1:0]    _zz_350_;
  wire       [1:0]    _zz_351_;
  wire                _zz_352_;
  wire       [0:0]    _zz_353_;
  wire       [9:0]    _zz_354_;
  wire       [31:0]   _zz_355_;
  wire       [31:0]   _zz_356_;
  wire       [31:0]   _zz_357_;
  wire       [31:0]   _zz_358_;
  wire       [31:0]   _zz_359_;
  wire       [31:0]   _zz_360_;
  wire       [31:0]   _zz_361_;
  wire                _zz_362_;
  wire                _zz_363_;
  wire                _zz_364_;
  wire       [0:0]    _zz_365_;
  wire       [0:0]    _zz_366_;
  wire       [0:0]    _zz_367_;
  wire       [0:0]    _zz_368_;
  wire                _zz_369_;
  wire       [0:0]    _zz_370_;
  wire       [7:0]    _zz_371_;
  wire       [31:0]   _zz_372_;
  wire       [31:0]   _zz_373_;
  wire                _zz_374_;
  wire                _zz_375_;
  wire       [0:0]    _zz_376_;
  wire       [1:0]    _zz_377_;
  wire       [1:0]    _zz_378_;
  wire       [1:0]    _zz_379_;
  wire                _zz_380_;
  wire       [0:0]    _zz_381_;
  wire       [4:0]    _zz_382_;
  wire       [31:0]   _zz_383_;
  wire       [31:0]   _zz_384_;
  wire       [31:0]   _zz_385_;
  wire       [31:0]   _zz_386_;
  wire       [31:0]   _zz_387_;
  wire       [31:0]   _zz_388_;
  wire       [31:0]   _zz_389_;
  wire       [31:0]   _zz_390_;
  wire       [31:0]   _zz_391_;
  wire                _zz_392_;
  wire       [2:0]    _zz_393_;
  wire       [2:0]    _zz_394_;
  wire                _zz_395_;
  wire       [0:0]    _zz_396_;
  wire       [1:0]    _zz_397_;
  wire       [31:0]   _zz_398_;
  wire                _zz_399_;
  wire                _zz_400_;
  wire       `AluBitwiseCtrlEnum_defaultEncoding_type decode_ALU_BITWISE_CTRL;
  wire       `AluBitwiseCtrlEnum_defaultEncoding_type _zz_1_;
  wire       `AluBitwiseCtrlEnum_defaultEncoding_type _zz_2_;
  wire       `AluBitwiseCtrlEnum_defaultEncoding_type _zz_3_;
  wire                decode_MEMORY_ENABLE;
  wire       `Src2CtrlEnum_defaultEncoding_type decode_SRC2_CTRL;
  wire       `Src2CtrlEnum_defaultEncoding_type _zz_4_;
  wire       `Src2CtrlEnum_defaultEncoding_type _zz_5_;
  wire       `Src2CtrlEnum_defaultEncoding_type _zz_6_;
  wire       [31:0]   writeBack_FORMAL_PC_NEXT;
  wire       [31:0]   memory_FORMAL_PC_NEXT;
  wire       [31:0]   execute_FORMAL_PC_NEXT;
  wire       [31:0]   decode_FORMAL_PC_NEXT;
  wire                decode_CSR_READ_OPCODE;
  wire                decode_CSR_WRITE_OPCODE;
  wire       `ShiftCtrlEnum_defaultEncoding_type decode_SHIFT_CTRL;
  wire       `ShiftCtrlEnum_defaultEncoding_type _zz_7_;
  wire       `ShiftCtrlEnum_defaultEncoding_type _zz_8_;
  wire       `ShiftCtrlEnum_defaultEncoding_type _zz_9_;
  wire                decode_IS_MUL;
  wire                decode_MEMORY_STORE;
  wire       `Src1CtrlEnum_defaultEncoding_type decode_SRC1_CTRL;
  wire       `Src1CtrlEnum_defaultEncoding_type _zz_10_;
  wire       `Src1CtrlEnum_defaultEncoding_type _zz_11_;
  wire       `Src1CtrlEnum_defaultEncoding_type _zz_12_;
  wire                decode_IS_CSR;
  wire                decode_BYPASSABLE_EXECUTE_STAGE;
  wire       [31:0]   writeBack_REGFILE_WRITE_DATA;
  wire       [31:0]   memory_REGFILE_WRITE_DATA;
  wire       [31:0]   execute_REGFILE_WRITE_DATA;
  wire                decode_IS_RS1_SIGNED;
  wire       `BranchCtrlEnum_defaultEncoding_type decode_BRANCH_CTRL;
  wire       `BranchCtrlEnum_defaultEncoding_type _zz_13_;
  wire       `BranchCtrlEnum_defaultEncoding_type _zz_14_;
  wire       `BranchCtrlEnum_defaultEncoding_type _zz_15_;
  wire                execute_BYPASSABLE_MEMORY_STAGE;
  wire                decode_BYPASSABLE_MEMORY_STAGE;
  wire       [31:0]   memory_PC;
  wire       `AluCtrlEnum_defaultEncoding_type decode_ALU_CTRL;
  wire       `AluCtrlEnum_defaultEncoding_type _zz_16_;
  wire       `AluCtrlEnum_defaultEncoding_type _zz_17_;
  wire       `AluCtrlEnum_defaultEncoding_type _zz_18_;
  wire                decode_SRC2_FORCE_ZERO;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_19_;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_20_;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_21_;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_22_;
  wire       `EnvCtrlEnum_defaultEncoding_type decode_ENV_CTRL;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_23_;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_24_;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_25_;
  wire                decode_SRC_LESS_UNSIGNED;
  wire                decode_IS_RS2_SIGNED;
  wire                decode_IS_DIV;
  wire       [1:0]    execute_MEMORY_ADDRESS_LOW;
  wire       [31:0]   execute_BRANCH_CALC;
  wire                execute_BRANCH_DO;
  wire       [31:0]   execute_PC;
  wire       `BranchCtrlEnum_defaultEncoding_type execute_BRANCH_CTRL;
  wire       `BranchCtrlEnum_defaultEncoding_type _zz_26_;
  wire                execute_IS_RS1_SIGNED;
  wire       [31:0]   execute_RS1;
  wire                execute_IS_DIV;
  wire                execute_IS_MUL;
  wire                execute_IS_RS2_SIGNED;
  wire                memory_IS_DIV;
  wire                memory_IS_MUL;
  wire                decode_RS2_USE;
  wire                decode_RS1_USE;
  wire                execute_REGFILE_WRITE_VALID;
  wire                execute_BYPASSABLE_EXECUTE_STAGE;
  wire                memory_REGFILE_WRITE_VALID;
  wire                memory_BYPASSABLE_MEMORY_STAGE;
  wire                writeBack_REGFILE_WRITE_VALID;
  reg        [31:0]   decode_RS2;
  reg        [31:0]   decode_RS1;
  wire       [31:0]   execute_SHIFT_RIGHT;
  wire       `ShiftCtrlEnum_defaultEncoding_type execute_SHIFT_CTRL;
  wire       `ShiftCtrlEnum_defaultEncoding_type _zz_27_;
  wire                execute_SRC_LESS_UNSIGNED;
  wire                execute_SRC2_FORCE_ZERO;
  wire                execute_SRC_USE_SUB_LESS;
  wire       [31:0]   _zz_28_;
  wire       `Src2CtrlEnum_defaultEncoding_type execute_SRC2_CTRL;
  wire       `Src2CtrlEnum_defaultEncoding_type _zz_29_;
  wire                execute_IS_RVC;
  wire       `Src1CtrlEnum_defaultEncoding_type execute_SRC1_CTRL;
  wire       `Src1CtrlEnum_defaultEncoding_type _zz_30_;
  wire                decode_SRC_USE_SUB_LESS;
  wire                decode_SRC_ADD_ZERO;
  wire       [31:0]   execute_SRC_ADD_SUB;
  wire                execute_SRC_LESS;
  wire       `AluCtrlEnum_defaultEncoding_type execute_ALU_CTRL;
  wire       `AluCtrlEnum_defaultEncoding_type _zz_31_;
  wire       [31:0]   execute_SRC2;
  wire       `AluBitwiseCtrlEnum_defaultEncoding_type execute_ALU_BITWISE_CTRL;
  wire       `AluBitwiseCtrlEnum_defaultEncoding_type _zz_32_;
  wire       [31:0]   _zz_33_;
  wire       [31:0]   _zz_34_;
  wire                _zz_35_;
  reg                 _zz_36_;
  wire       [31:0]   decode_INSTRUCTION_ANTICIPATED;
  reg                 decode_REGFILE_WRITE_VALID;
  wire       `Src2CtrlEnum_defaultEncoding_type _zz_37_;
  wire       `AluBitwiseCtrlEnum_defaultEncoding_type _zz_38_;
  wire       `BranchCtrlEnum_defaultEncoding_type _zz_39_;
  wire       `Src1CtrlEnum_defaultEncoding_type _zz_40_;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_41_;
  wire       `ShiftCtrlEnum_defaultEncoding_type _zz_42_;
  wire       `AluCtrlEnum_defaultEncoding_type _zz_43_;
  reg        [31:0]   _zz_44_;
  wire       [31:0]   execute_SRC1;
  wire                execute_CSR_READ_OPCODE;
  wire                execute_CSR_WRITE_OPCODE;
  wire                execute_IS_CSR;
  wire       `EnvCtrlEnum_defaultEncoding_type memory_ENV_CTRL;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_45_;
  wire       `EnvCtrlEnum_defaultEncoding_type execute_ENV_CTRL;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_46_;
  wire       `EnvCtrlEnum_defaultEncoding_type writeBack_ENV_CTRL;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_47_;
  reg        [31:0]   _zz_48_;
  wire       [31:0]   memory_INSTRUCTION;
  wire       [1:0]    memory_MEMORY_ADDRESS_LOW;
  wire       [31:0]   memory_MEMORY_READ_DATA;
  wire                memory_MEMORY_STORE;
  wire                memory_MEMORY_ENABLE;
  wire       [31:0]   execute_SRC_ADD;
  wire       [31:0]   execute_RS2;
  wire       [31:0]   execute_INSTRUCTION;
  wire                execute_MEMORY_STORE;
  wire                execute_MEMORY_ENABLE;
  wire                execute_ALIGNEMENT_FAULT;
  reg        [31:0]   _zz_49_;
  wire       [31:0]   decode_PC;
  wire       [31:0]   decode_INSTRUCTION;
  wire                decode_IS_RVC;
  wire       [31:0]   writeBack_PC;
  wire       [31:0]   writeBack_INSTRUCTION;
  wire                decode_arbitration_haltItself;
  reg                 decode_arbitration_haltByOther;
  reg                 decode_arbitration_removeIt;
  wire                decode_arbitration_flushIt;
  wire                decode_arbitration_flushNext;
  wire                decode_arbitration_isValid;
  wire                decode_arbitration_isStuck;
  wire                decode_arbitration_isStuckByOthers;
  wire                decode_arbitration_isFlushed;
  wire                decode_arbitration_isMoving;
  wire                decode_arbitration_isFiring;
  reg                 execute_arbitration_haltItself;
  wire                execute_arbitration_haltByOther;
  reg                 execute_arbitration_removeIt;
  wire                execute_arbitration_flushIt;
  reg                 execute_arbitration_flushNext;
  reg                 execute_arbitration_isValid;
  wire                execute_arbitration_isStuck;
  wire                execute_arbitration_isStuckByOthers;
  wire                execute_arbitration_isFlushed;
  wire                execute_arbitration_isMoving;
  wire                execute_arbitration_isFiring;
  reg                 memory_arbitration_haltItself;
  wire                memory_arbitration_haltByOther;
  reg                 memory_arbitration_removeIt;
  wire                memory_arbitration_flushIt;
  wire                memory_arbitration_flushNext;
  reg                 memory_arbitration_isValid;
  wire                memory_arbitration_isStuck;
  wire                memory_arbitration_isStuckByOthers;
  wire                memory_arbitration_isFlushed;
  wire                memory_arbitration_isMoving;
  wire                memory_arbitration_isFiring;
  wire                writeBack_arbitration_haltItself;
  wire                writeBack_arbitration_haltByOther;
  reg                 writeBack_arbitration_removeIt;
  wire                writeBack_arbitration_flushIt;
  reg                 writeBack_arbitration_flushNext;
  reg                 writeBack_arbitration_isValid;
  wire                writeBack_arbitration_isStuck;
  wire                writeBack_arbitration_isStuckByOthers;
  wire                writeBack_arbitration_isFlushed;
  wire                writeBack_arbitration_isMoving;
  wire                writeBack_arbitration_isFiring;
  wire       [31:0]   lastStageInstruction /* verilator public */ ;
  wire       [31:0]   lastStagePc /* verilator public */ ;
  wire                lastStageIsValid /* verilator public */ ;
  wire                lastStageIsFiring /* verilator public */ ;
  reg                 IBusSimplePlugin_fetcherHalt;
  reg                 IBusSimplePlugin_incomingInstruction;
  wire                IBusSimplePlugin_pcValids_0;
  wire                IBusSimplePlugin_pcValids_1;
  wire                IBusSimplePlugin_pcValids_2;
  wire                IBusSimplePlugin_pcValids_3;
  wire                CsrPlugin_inWfi /* verilator public */ ;
  wire                CsrPlugin_thirdPartyWake;
  reg                 CsrPlugin_jumpInterface_valid;
  reg        [31:0]   CsrPlugin_jumpInterface_payload;
  wire                CsrPlugin_exceptionPendings_0;
  wire                CsrPlugin_exceptionPendings_1;
  wire                CsrPlugin_exceptionPendings_2;
  wire                CsrPlugin_exceptionPendings_3;
  wire                contextSwitching;
  reg        [1:0]    CsrPlugin_privilege;
  wire                CsrPlugin_forceMachineWire;
  wire                CsrPlugin_allowInterrupts;
  wire                CsrPlugin_allowException;
  wire                BranchPlugin_jumpInterface_valid;
  wire       [31:0]   BranchPlugin_jumpInterface_payload;
  wire                IBusSimplePlugin_externalFlush;
  wire                IBusSimplePlugin_jump_pcLoad_valid;
  wire       [31:0]   IBusSimplePlugin_jump_pcLoad_payload;
  wire       [1:0]    _zz_50_;
  wire                IBusSimplePlugin_fetchPc_output_valid;
  wire                IBusSimplePlugin_fetchPc_output_ready;
  wire       [31:0]   IBusSimplePlugin_fetchPc_output_payload;
  reg        [31:0]   IBusSimplePlugin_fetchPc_pcReg /* verilator public */ ;
  reg                 IBusSimplePlugin_fetchPc_correction;
  reg                 IBusSimplePlugin_fetchPc_correctionReg;
  wire                IBusSimplePlugin_fetchPc_corrected;
  reg                 IBusSimplePlugin_fetchPc_pcRegPropagate;
  reg                 IBusSimplePlugin_fetchPc_booted;
  reg                 IBusSimplePlugin_fetchPc_inc;
  reg        [31:0]   IBusSimplePlugin_fetchPc_pc;
  reg                 IBusSimplePlugin_fetchPc_flushed;
  reg                 IBusSimplePlugin_decodePc_flushed;
  reg        [31:0]   IBusSimplePlugin_decodePc_pcReg /* verilator public */ ;
  wire       [31:0]   IBusSimplePlugin_decodePc_pcPlus;
  wire                IBusSimplePlugin_decodePc_injectedDecode;
  wire                IBusSimplePlugin_iBusRsp_redoFetch;
  wire                IBusSimplePlugin_iBusRsp_stages_0_input_valid;
  wire                IBusSimplePlugin_iBusRsp_stages_0_input_ready;
  wire       [31:0]   IBusSimplePlugin_iBusRsp_stages_0_input_payload;
  wire                IBusSimplePlugin_iBusRsp_stages_0_output_valid;
  wire                IBusSimplePlugin_iBusRsp_stages_0_output_ready;
  wire       [31:0]   IBusSimplePlugin_iBusRsp_stages_0_output_payload;
  wire                IBusSimplePlugin_iBusRsp_stages_0_halt;
  wire                IBusSimplePlugin_iBusRsp_stages_1_input_valid;
  wire                IBusSimplePlugin_iBusRsp_stages_1_input_ready;
  wire       [31:0]   IBusSimplePlugin_iBusRsp_stages_1_input_payload;
  wire                IBusSimplePlugin_iBusRsp_stages_1_output_valid;
  wire                IBusSimplePlugin_iBusRsp_stages_1_output_ready;
  wire       [31:0]   IBusSimplePlugin_iBusRsp_stages_1_output_payload;
  reg                 IBusSimplePlugin_iBusRsp_stages_1_halt;
  wire                IBusSimplePlugin_iBusRsp_stages_2_input_valid;
  wire                IBusSimplePlugin_iBusRsp_stages_2_input_ready;
  wire       [31:0]   IBusSimplePlugin_iBusRsp_stages_2_input_payload;
  wire                IBusSimplePlugin_iBusRsp_stages_2_output_valid;
  wire                IBusSimplePlugin_iBusRsp_stages_2_output_ready;
  wire       [31:0]   IBusSimplePlugin_iBusRsp_stages_2_output_payload;
  wire                IBusSimplePlugin_iBusRsp_stages_2_halt;
  wire                _zz_51_;
  wire                _zz_52_;
  wire                _zz_53_;
  wire                IBusSimplePlugin_iBusRsp_flush;
  wire                _zz_54_;
  wire                _zz_55_;
  reg                 _zz_56_;
  wire                _zz_57_;
  reg                 _zz_58_;
  reg        [31:0]   _zz_59_;
  reg                 IBusSimplePlugin_iBusRsp_readyForError;
  wire                IBusSimplePlugin_iBusRsp_output_valid;
  wire                IBusSimplePlugin_iBusRsp_output_ready;
  wire       [31:0]   IBusSimplePlugin_iBusRsp_output_payload_pc;
  wire                IBusSimplePlugin_iBusRsp_output_payload_rsp_error;
  wire       [31:0]   IBusSimplePlugin_iBusRsp_output_payload_rsp_inst;
  wire                IBusSimplePlugin_iBusRsp_output_payload_isRvc;
  wire                IBusSimplePlugin_decompressor_input_valid;
  wire                IBusSimplePlugin_decompressor_input_ready;
  wire       [31:0]   IBusSimplePlugin_decompressor_input_payload_pc;
  wire                IBusSimplePlugin_decompressor_input_payload_rsp_error;
  wire       [31:0]   IBusSimplePlugin_decompressor_input_payload_rsp_inst;
  wire                IBusSimplePlugin_decompressor_input_payload_isRvc;
  wire                IBusSimplePlugin_decompressor_output_valid;
  wire                IBusSimplePlugin_decompressor_output_ready;
  wire       [31:0]   IBusSimplePlugin_decompressor_output_payload_pc;
  wire                IBusSimplePlugin_decompressor_output_payload_rsp_error;
  wire       [31:0]   IBusSimplePlugin_decompressor_output_payload_rsp_inst;
  wire                IBusSimplePlugin_decompressor_output_payload_isRvc;
  wire                IBusSimplePlugin_decompressor_flushNext;
  wire                IBusSimplePlugin_decompressor_consumeCurrent;
  reg                 IBusSimplePlugin_decompressor_bufferValid;
  reg        [15:0]   IBusSimplePlugin_decompressor_bufferData;
  wire                IBusSimplePlugin_decompressor_isInputLowRvc;
  wire                IBusSimplePlugin_decompressor_isInputHighRvc;
  reg                 IBusSimplePlugin_decompressor_throw2BytesReg;
  wire                IBusSimplePlugin_decompressor_throw2Bytes;
  wire                IBusSimplePlugin_decompressor_unaligned;
  wire       [31:0]   IBusSimplePlugin_decompressor_raw;
  wire                IBusSimplePlugin_decompressor_isRvc;
  wire       [15:0]   _zz_60_;
  reg        [31:0]   IBusSimplePlugin_decompressor_decompressed;
  wire       [4:0]    _zz_61_;
  wire       [4:0]    _zz_62_;
  wire       [11:0]   _zz_63_;
  wire                _zz_64_;
  reg        [11:0]   _zz_65_;
  wire                _zz_66_;
  reg        [9:0]    _zz_67_;
  wire       [20:0]   _zz_68_;
  wire                _zz_69_;
  reg        [14:0]   _zz_70_;
  wire                _zz_71_;
  reg        [2:0]    _zz_72_;
  wire                _zz_73_;
  reg        [9:0]    _zz_74_;
  wire       [20:0]   _zz_75_;
  wire                _zz_76_;
  reg        [4:0]    _zz_77_;
  wire       [12:0]   _zz_78_;
  wire       [4:0]    _zz_79_;
  wire       [4:0]    _zz_80_;
  wire       [4:0]    _zz_81_;
  wire                _zz_82_;
  reg        [2:0]    _zz_83_;
  reg        [2:0]    _zz_84_;
  wire                _zz_85_;
  reg        [6:0]    _zz_86_;
  wire                IBusSimplePlugin_decompressor_bufferFill;
  wire                IBusSimplePlugin_injector_decodeInput_valid;
  wire                IBusSimplePlugin_injector_decodeInput_ready;
  wire       [31:0]   IBusSimplePlugin_injector_decodeInput_payload_pc;
  wire                IBusSimplePlugin_injector_decodeInput_payload_rsp_error;
  wire       [31:0]   IBusSimplePlugin_injector_decodeInput_payload_rsp_inst;
  wire                IBusSimplePlugin_injector_decodeInput_payload_isRvc;
  reg                 _zz_87_;
  reg        [31:0]   _zz_88_;
  reg                 _zz_89_;
  reg        [31:0]   _zz_90_;
  reg                 _zz_91_;
  reg                 IBusSimplePlugin_injector_nextPcCalc_valids_0;
  reg                 IBusSimplePlugin_injector_nextPcCalc_valids_1;
  reg                 IBusSimplePlugin_injector_nextPcCalc_valids_2;
  reg                 IBusSimplePlugin_injector_nextPcCalc_valids_3;
  reg        [31:0]   IBusSimplePlugin_injector_formal_rawInDecode;
  wire                IBusSimplePlugin_cmd_valid;
  wire                IBusSimplePlugin_cmd_ready;
  wire       [31:0]   IBusSimplePlugin_cmd_payload_pc;
  wire                IBusSimplePlugin_pending_inc;
  wire                IBusSimplePlugin_pending_dec;
  reg        [2:0]    IBusSimplePlugin_pending_value;
  wire       [2:0]    IBusSimplePlugin_pending_next;
  wire                IBusSimplePlugin_cmdFork_canEmit;
  wire                IBusSimplePlugin_rspJoin_rspBuffer_output_valid;
  wire                IBusSimplePlugin_rspJoin_rspBuffer_output_ready;
  wire                IBusSimplePlugin_rspJoin_rspBuffer_output_payload_error;
  wire       [31:0]   IBusSimplePlugin_rspJoin_rspBuffer_output_payload_inst;
  reg        [2:0]    IBusSimplePlugin_rspJoin_rspBuffer_discardCounter;
  wire                IBusSimplePlugin_rspJoin_rspBuffer_flush;
  wire       [31:0]   IBusSimplePlugin_rspJoin_fetchRsp_pc;
  reg                 IBusSimplePlugin_rspJoin_fetchRsp_rsp_error;
  wire       [31:0]   IBusSimplePlugin_rspJoin_fetchRsp_rsp_inst;
  wire                IBusSimplePlugin_rspJoin_fetchRsp_isRvc;
  wire                IBusSimplePlugin_rspJoin_join_valid;
  wire                IBusSimplePlugin_rspJoin_join_ready;
  wire       [31:0]   IBusSimplePlugin_rspJoin_join_payload_pc;
  wire                IBusSimplePlugin_rspJoin_join_payload_rsp_error;
  wire       [31:0]   IBusSimplePlugin_rspJoin_join_payload_rsp_inst;
  wire                IBusSimplePlugin_rspJoin_join_payload_isRvc;
  wire                IBusSimplePlugin_rspJoin_exceptionDetected;
  wire                _zz_92_;
  wire                _zz_93_;
  reg                 execute_DBusSimplePlugin_skipCmd;
  reg        [31:0]   _zz_94_;
  reg        [3:0]    _zz_95_;
  wire       [3:0]    execute_DBusSimplePlugin_formalMask;
  reg        [31:0]   memory_DBusSimplePlugin_rspShifted;
  wire                _zz_96_;
  reg        [31:0]   _zz_97_;
  wire                _zz_98_;
  reg        [31:0]   _zz_99_;
  reg        [31:0]   memory_DBusSimplePlugin_rspFormated;
  wire       [1:0]    CsrPlugin_misa_base;
  wire       [25:0]   CsrPlugin_misa_extensions;
  wire       [1:0]    CsrPlugin_mtvec_mode;
  wire       [29:0]   CsrPlugin_mtvec_base;
  reg        [31:0]   CsrPlugin_mepc;
  reg                 CsrPlugin_mstatus_MIE;
  reg                 CsrPlugin_mstatus_MPIE;
  reg        [1:0]    CsrPlugin_mstatus_MPP;
  reg                 CsrPlugin_mip_MEIP;
  reg                 CsrPlugin_mip_MTIP;
  reg                 CsrPlugin_mip_MSIP;
  reg                 CsrPlugin_mie_MEIE;
  reg                 CsrPlugin_mie_MTIE;
  reg                 CsrPlugin_mie_MSIE;
  reg        [31:0]   CsrPlugin_mscratch;
  reg                 CsrPlugin_mcause_interrupt;
  reg        [3:0]    CsrPlugin_mcause_exceptionCode;
  reg        [31:0]   CsrPlugin_mtval;
  reg        [63:0]   CsrPlugin_mcycle = 64'b0000000000000000000000000000000000000000000000000000000000000000;
  reg        [63:0]   CsrPlugin_minstret = 64'b0000000000000000000000000000000000000000000000000000000000000000;
  wire                _zz_100_;
  wire                _zz_101_;
  wire                _zz_102_;
  reg                 CsrPlugin_interrupt_valid;
  reg        [3:0]    CsrPlugin_interrupt_code /* verilator public */ ;
  reg        [1:0]    CsrPlugin_interrupt_targetPrivilege;
  wire                CsrPlugin_exception;
  wire                CsrPlugin_lastStageWasWfi;
  reg                 CsrPlugin_pipelineLiberator_pcValids_0;
  reg                 CsrPlugin_pipelineLiberator_pcValids_1;
  reg                 CsrPlugin_pipelineLiberator_pcValids_2;
  wire                CsrPlugin_pipelineLiberator_active;
  reg                 CsrPlugin_pipelineLiberator_done;
  wire                CsrPlugin_interruptJump /* verilator public */ ;
  reg                 CsrPlugin_hadException;
  wire       [1:0]    CsrPlugin_targetPrivilege;
  wire       [3:0]    CsrPlugin_trapCause;
  reg        [1:0]    CsrPlugin_xtvec_mode;
  reg        [29:0]   CsrPlugin_xtvec_base;
  reg                 execute_CsrPlugin_wfiWake;
  wire                execute_CsrPlugin_blockedBySideEffects;
  reg                 execute_CsrPlugin_illegalAccess;
  reg                 execute_CsrPlugin_illegalInstruction;
  wire       [31:0]   execute_CsrPlugin_readData;
  wire                execute_CsrPlugin_writeInstruction;
  wire                execute_CsrPlugin_readInstruction;
  wire                execute_CsrPlugin_writeEnable;
  wire                execute_CsrPlugin_readEnable;
  wire       [31:0]   execute_CsrPlugin_readToWriteData;
  reg        [31:0]   execute_CsrPlugin_writeData;
  wire       [11:0]   execute_CsrPlugin_csrAddress;
  wire       [28:0]   _zz_103_;
  wire                _zz_104_;
  wire                _zz_105_;
  wire                _zz_106_;
  wire                _zz_107_;
  wire                _zz_108_;
  wire                _zz_109_;
  wire                _zz_110_;
  wire       `AluCtrlEnum_defaultEncoding_type _zz_111_;
  wire       `ShiftCtrlEnum_defaultEncoding_type _zz_112_;
  wire       `EnvCtrlEnum_defaultEncoding_type _zz_113_;
  wire       `Src1CtrlEnum_defaultEncoding_type _zz_114_;
  wire       `BranchCtrlEnum_defaultEncoding_type _zz_115_;
  wire       `AluBitwiseCtrlEnum_defaultEncoding_type _zz_116_;
  wire       `Src2CtrlEnum_defaultEncoding_type _zz_117_;
  wire       [3:0]    decode_RegFilePlugin_regFileReadAddress1;
  wire       [3:0]    decode_RegFilePlugin_regFileReadAddress2;
  wire       [31:0]   decode_RegFilePlugin_rs1Data;
  wire       [31:0]   decode_RegFilePlugin_rs2Data;
  reg                 lastStageRegFileWrite_valid /* verilator public */ ;
  wire       [3:0]    lastStageRegFileWrite_payload_address /* verilator public */ ;
  wire       [31:0]   lastStageRegFileWrite_payload_data /* verilator public */ ;
  reg                 _zz_118_;
  reg        [31:0]   execute_IntAluPlugin_bitwise;
  reg        [31:0]   _zz_119_;
  reg        [31:0]   _zz_120_;
  wire                _zz_121_;
  reg        [19:0]   _zz_122_;
  wire                _zz_123_;
  reg        [19:0]   _zz_124_;
  reg        [31:0]   _zz_125_;
  reg        [31:0]   execute_SrcPlugin_addSub;
  wire                execute_SrcPlugin_less;
  wire       [4:0]    execute_FullBarrelShifterPlugin_amplitude;
  reg        [31:0]   _zz_126_;
  wire       [31:0]   execute_FullBarrelShifterPlugin_reversed;
  reg        [31:0]   _zz_127_;
  reg                 _zz_128_;
  reg                 _zz_129_;
  reg                 _zz_130_;
  reg        [4:0]    _zz_131_;
  reg        [31:0]   _zz_132_;
  wire                _zz_133_;
  wire                _zz_134_;
  wire                _zz_135_;
  wire                _zz_136_;
  wire                _zz_137_;
  wire                _zz_138_;
  reg        [32:0]   memory_MulDivIterativePlugin_rs1;
  reg        [31:0]   memory_MulDivIterativePlugin_rs2;
  reg        [64:0]   memory_MulDivIterativePlugin_accumulator;
  wire                memory_MulDivIterativePlugin_frontendOk;
  reg                 memory_MulDivIterativePlugin_mul_counter_willIncrement;
  reg                 memory_MulDivIterativePlugin_mul_counter_willClear;
  reg        [4:0]    memory_MulDivIterativePlugin_mul_counter_valueNext;
  reg        [4:0]    memory_MulDivIterativePlugin_mul_counter_value;
  wire                memory_MulDivIterativePlugin_mul_counter_willOverflowIfInc;
  wire                memory_MulDivIterativePlugin_mul_counter_willOverflow;
  reg                 memory_MulDivIterativePlugin_div_needRevert;
  reg                 memory_MulDivIterativePlugin_div_counter_willIncrement;
  reg                 memory_MulDivIterativePlugin_div_counter_willClear;
  reg        [4:0]    memory_MulDivIterativePlugin_div_counter_valueNext;
  reg        [4:0]    memory_MulDivIterativePlugin_div_counter_value;
  wire                memory_MulDivIterativePlugin_div_counter_willOverflowIfInc;
  wire                memory_MulDivIterativePlugin_div_counter_willOverflow;
  reg                 memory_MulDivIterativePlugin_div_done;
  reg        [31:0]   memory_MulDivIterativePlugin_div_result;
  wire       [31:0]   _zz_139_;
  wire       [32:0]   memory_MulDivIterativePlugin_div_stage_0_remainderShifted;
  wire       [32:0]   memory_MulDivIterativePlugin_div_stage_0_remainderMinusDenominator;
  wire       [31:0]   memory_MulDivIterativePlugin_div_stage_0_outRemainder;
  wire       [31:0]   memory_MulDivIterativePlugin_div_stage_0_outNumerator;
  wire       [32:0]   memory_MulDivIterativePlugin_div_stage_1_remainderShifted;
  wire       [32:0]   memory_MulDivIterativePlugin_div_stage_1_remainderMinusDenominator;
  wire       [31:0]   memory_MulDivIterativePlugin_div_stage_1_outRemainder;
  wire       [31:0]   memory_MulDivIterativePlugin_div_stage_1_outNumerator;
  wire       [31:0]   _zz_140_;
  wire                _zz_141_;
  wire                _zz_142_;
  reg        [32:0]   _zz_143_;
  wire                execute_BranchPlugin_eq;
  wire       [2:0]    _zz_144_;
  reg                 _zz_145_;
  reg                 _zz_146_;
  wire       [31:0]   execute_BranchPlugin_branch_src1;
  wire                _zz_147_;
  reg        [10:0]   _zz_148_;
  wire                _zz_149_;
  reg        [19:0]   _zz_150_;
  wire                _zz_151_;
  reg        [18:0]   _zz_152_;
  reg        [31:0]   _zz_153_;
  wire       [31:0]   execute_BranchPlugin_branch_src2;
  wire       [31:0]   execute_BranchPlugin_branchAdder;
  reg        [31:0]   decode_to_execute_RS1;
  reg        [1:0]    execute_to_memory_MEMORY_ADDRESS_LOW;
  reg                 decode_to_execute_IS_DIV;
  reg                 execute_to_memory_IS_DIV;
  reg                 decode_to_execute_IS_RVC;
  reg                 decode_to_execute_IS_RS2_SIGNED;
  reg                 decode_to_execute_SRC_USE_SUB_LESS;
  reg                 decode_to_execute_SRC_LESS_UNSIGNED;
  reg        `EnvCtrlEnum_defaultEncoding_type decode_to_execute_ENV_CTRL;
  reg        `EnvCtrlEnum_defaultEncoding_type execute_to_memory_ENV_CTRL;
  reg        `EnvCtrlEnum_defaultEncoding_type memory_to_writeBack_ENV_CTRL;
  reg                 decode_to_execute_SRC2_FORCE_ZERO;
  reg        `AluCtrlEnum_defaultEncoding_type decode_to_execute_ALU_CTRL;
  reg                 decode_to_execute_REGFILE_WRITE_VALID;
  reg                 execute_to_memory_REGFILE_WRITE_VALID;
  reg                 memory_to_writeBack_REGFILE_WRITE_VALID;
  reg        [31:0]   decode_to_execute_PC;
  reg        [31:0]   execute_to_memory_PC;
  reg        [31:0]   memory_to_writeBack_PC;
  reg                 decode_to_execute_BYPASSABLE_MEMORY_STAGE;
  reg                 execute_to_memory_BYPASSABLE_MEMORY_STAGE;
  reg        `BranchCtrlEnum_defaultEncoding_type decode_to_execute_BRANCH_CTRL;
  reg                 decode_to_execute_IS_RS1_SIGNED;
  reg        [31:0]   execute_to_memory_REGFILE_WRITE_DATA;
  reg        [31:0]   memory_to_writeBack_REGFILE_WRITE_DATA;
  reg                 decode_to_execute_BYPASSABLE_EXECUTE_STAGE;
  reg                 decode_to_execute_IS_CSR;
  reg        `Src1CtrlEnum_defaultEncoding_type decode_to_execute_SRC1_CTRL;
  reg                 decode_to_execute_MEMORY_STORE;
  reg                 execute_to_memory_MEMORY_STORE;
  reg        [31:0]   decode_to_execute_INSTRUCTION;
  reg        [31:0]   execute_to_memory_INSTRUCTION;
  reg        [31:0]   memory_to_writeBack_INSTRUCTION;
  reg                 decode_to_execute_IS_MUL;
  reg                 execute_to_memory_IS_MUL;
  reg        `ShiftCtrlEnum_defaultEncoding_type decode_to_execute_SHIFT_CTRL;
  reg                 decode_to_execute_CSR_WRITE_OPCODE;
  reg                 decode_to_execute_CSR_READ_OPCODE;
  reg        [31:0]   decode_to_execute_FORMAL_PC_NEXT;
  reg        [31:0]   execute_to_memory_FORMAL_PC_NEXT;
  reg        [31:0]   memory_to_writeBack_FORMAL_PC_NEXT;
  reg        `Src2CtrlEnum_defaultEncoding_type decode_to_execute_SRC2_CTRL;
  reg                 decode_to_execute_MEMORY_ENABLE;
  reg                 execute_to_memory_MEMORY_ENABLE;
  reg        `AluBitwiseCtrlEnum_defaultEncoding_type decode_to_execute_ALU_BITWISE_CTRL;
  reg        [31:0]   decode_to_execute_RS2;
  reg                 execute_CsrPlugin_csr_768;
  reg                 execute_CsrPlugin_csr_836;
  reg                 execute_CsrPlugin_csr_772;
  reg                 execute_CsrPlugin_csr_832;
  reg                 execute_CsrPlugin_csr_834;
  reg        [31:0]   _zz_154_;
  reg        [31:0]   _zz_155_;
  reg        [31:0]   _zz_156_;
  reg        [31:0]   _zz_157_;
  reg        [31:0]   _zz_158_;
  `ifndef SYNTHESIS
  reg [39:0] decode_ALU_BITWISE_CTRL_string;
  reg [39:0] _zz_1__string;
  reg [39:0] _zz_2__string;
  reg [39:0] _zz_3__string;
  reg [23:0] decode_SRC2_CTRL_string;
  reg [23:0] _zz_4__string;
  reg [23:0] _zz_5__string;
  reg [23:0] _zz_6__string;
  reg [71:0] decode_SHIFT_CTRL_string;
  reg [71:0] _zz_7__string;
  reg [71:0] _zz_8__string;
  reg [71:0] _zz_9__string;
  reg [95:0] decode_SRC1_CTRL_string;
  reg [95:0] _zz_10__string;
  reg [95:0] _zz_11__string;
  reg [95:0] _zz_12__string;
  reg [31:0] decode_BRANCH_CTRL_string;
  reg [31:0] _zz_13__string;
  reg [31:0] _zz_14__string;
  reg [31:0] _zz_15__string;
  reg [63:0] decode_ALU_CTRL_string;
  reg [63:0] _zz_16__string;
  reg [63:0] _zz_17__string;
  reg [63:0] _zz_18__string;
  reg [31:0] _zz_19__string;
  reg [31:0] _zz_20__string;
  reg [31:0] _zz_21__string;
  reg [31:0] _zz_22__string;
  reg [31:0] decode_ENV_CTRL_string;
  reg [31:0] _zz_23__string;
  reg [31:0] _zz_24__string;
  reg [31:0] _zz_25__string;
  reg [31:0] execute_BRANCH_CTRL_string;
  reg [31:0] _zz_26__string;
  reg [71:0] execute_SHIFT_CTRL_string;
  reg [71:0] _zz_27__string;
  reg [23:0] execute_SRC2_CTRL_string;
  reg [23:0] _zz_29__string;
  reg [95:0] execute_SRC1_CTRL_string;
  reg [95:0] _zz_30__string;
  reg [63:0] execute_ALU_CTRL_string;
  reg [63:0] _zz_31__string;
  reg [39:0] execute_ALU_BITWISE_CTRL_string;
  reg [39:0] _zz_32__string;
  reg [23:0] _zz_37__string;
  reg [39:0] _zz_38__string;
  reg [31:0] _zz_39__string;
  reg [95:0] _zz_40__string;
  reg [31:0] _zz_41__string;
  reg [71:0] _zz_42__string;
  reg [63:0] _zz_43__string;
  reg [31:0] memory_ENV_CTRL_string;
  reg [31:0] _zz_45__string;
  reg [31:0] execute_ENV_CTRL_string;
  reg [31:0] _zz_46__string;
  reg [31:0] writeBack_ENV_CTRL_string;
  reg [31:0] _zz_47__string;
  reg [63:0] _zz_111__string;
  reg [71:0] _zz_112__string;
  reg [31:0] _zz_113__string;
  reg [95:0] _zz_114__string;
  reg [31:0] _zz_115__string;
  reg [39:0] _zz_116__string;
  reg [23:0] _zz_117__string;
  reg [31:0] decode_to_execute_ENV_CTRL_string;
  reg [31:0] execute_to_memory_ENV_CTRL_string;
  reg [31:0] memory_to_writeBack_ENV_CTRL_string;
  reg [63:0] decode_to_execute_ALU_CTRL_string;
  reg [31:0] decode_to_execute_BRANCH_CTRL_string;
  reg [95:0] decode_to_execute_SRC1_CTRL_string;
  reg [71:0] decode_to_execute_SHIFT_CTRL_string;
  reg [23:0] decode_to_execute_SRC2_CTRL_string;
  reg [39:0] decode_to_execute_ALU_BITWISE_CTRL_string;
  `endif

  reg [31:0] RegFilePlugin_regFile [0:15] /* verilator public */ ;

  assign _zz_163_ = (writeBack_arbitration_isValid && writeBack_REGFILE_WRITE_VALID);
  assign _zz_164_ = 1'b1;
  assign _zz_165_ = (memory_arbitration_isValid && memory_REGFILE_WRITE_VALID);
  assign _zz_166_ = (execute_arbitration_isValid && execute_REGFILE_WRITE_VALID);
  assign _zz_167_ = (execute_arbitration_isValid && execute_IS_CSR);
  assign _zz_168_ = (memory_arbitration_isValid && memory_IS_MUL);
  assign _zz_169_ = (memory_arbitration_isValid && memory_IS_DIV);
  assign _zz_170_ = (memory_MulDivIterativePlugin_frontendOk && (! memory_MulDivIterativePlugin_mul_counter_willOverflowIfInc));
  assign _zz_171_ = (CsrPlugin_hadException || CsrPlugin_interruptJump);
  assign _zz_172_ = (writeBack_arbitration_isValid && (writeBack_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET));
  assign _zz_173_ = writeBack_INSTRUCTION[29 : 28];
  assign _zz_174_ = (IBusSimplePlugin_jump_pcLoad_valid && ((! decode_arbitration_isStuck) || decode_arbitration_removeIt));
  assign _zz_175_ = (writeBack_arbitration_isValid && writeBack_REGFILE_WRITE_VALID);
  assign _zz_176_ = (1'b0 || (! 1'b1));
  assign _zz_177_ = (memory_arbitration_isValid && memory_REGFILE_WRITE_VALID);
  assign _zz_178_ = (1'b0 || (! memory_BYPASSABLE_MEMORY_STAGE));
  assign _zz_179_ = (execute_arbitration_isValid && execute_REGFILE_WRITE_VALID);
  assign _zz_180_ = (1'b0 || (! execute_BYPASSABLE_EXECUTE_STAGE));
  assign _zz_181_ = (memory_MulDivIterativePlugin_frontendOk && (! memory_MulDivIterativePlugin_div_done));
  assign _zz_182_ = (! memory_arbitration_isStuck);
  assign _zz_183_ = (IBusSimplePlugin_decompressor_output_ready && IBusSimplePlugin_decompressor_input_valid);
  assign _zz_184_ = (CsrPlugin_mstatus_MIE || (CsrPlugin_privilege < (2'b11)));
  assign _zz_185_ = ((_zz_100_ && 1'b1) && (! 1'b0));
  assign _zz_186_ = ((_zz_101_ && 1'b1) && (! 1'b0));
  assign _zz_187_ = ((_zz_102_ && 1'b1) && (! 1'b0));
  assign _zz_188_ = {_zz_60_[1 : 0],_zz_60_[15 : 13]};
  assign _zz_189_ = _zz_60_[6 : 5];
  assign _zz_190_ = _zz_60_[11 : 10];
  assign _zz_191_ = memory_INSTRUCTION[13 : 12];
  assign _zz_192_ = execute_INSTRUCTION[13];
  assign _zz_193_ = _zz_103_[18 : 18];
  assign _zz_194_ = (decode_IS_RVC ? (3'b010) : (3'b100));
  assign _zz_195_ = {29'd0, _zz_194_};
  assign _zz_196_ = _zz_103_[1 : 1];
  assign _zz_197_ = _zz_103_[19 : 19];
  assign _zz_198_ = _zz_103_[25 : 25];
  assign _zz_199_ = _zz_103_[21 : 21];
  assign _zz_200_ = _zz_103_[4 : 4];
  assign _zz_201_ = _zz_103_[5 : 5];
  assign _zz_202_ = _zz_103_[16 : 16];
  assign _zz_203_ = _zz_103_[6 : 6];
  assign _zz_204_ = _zz_103_[0 : 0];
  assign _zz_205_ = _zz_103_[7 : 7];
  assign _zz_206_ = _zz_103_[28 : 28];
  assign _zz_207_ = ($signed(_zz_209_) >>> execute_FullBarrelShifterPlugin_amplitude);
  assign _zz_208_ = _zz_207_[31 : 0];
  assign _zz_209_ = {((execute_SHIFT_CTRL == `ShiftCtrlEnum_defaultEncoding_SRA_1) && execute_FullBarrelShifterPlugin_reversed[31]),execute_FullBarrelShifterPlugin_reversed};
  assign _zz_210_ = _zz_103_[13 : 13];
  assign _zz_211_ = _zz_103_[24 : 24];
  assign _zz_212_ = _zz_103_[17 : 17];
  assign _zz_213_ = (_zz_50_ & (~ _zz_214_));
  assign _zz_214_ = (_zz_50_ - (2'b01));
  assign _zz_215_ = {IBusSimplePlugin_fetchPc_inc,(2'b00)};
  assign _zz_216_ = {29'd0, _zz_215_};
  assign _zz_217_ = (decode_IS_RVC ? (3'b010) : (3'b100));
  assign _zz_218_ = {29'd0, _zz_217_};
  assign _zz_219_ = {{_zz_70_,_zz_60_[6 : 2]},12'h0};
  assign _zz_220_ = {{{(4'b0000),_zz_60_[8 : 7]},_zz_60_[12 : 9]},(2'b00)};
  assign _zz_221_ = {{{(4'b0000),_zz_60_[8 : 7]},_zz_60_[12 : 9]},(2'b00)};
  assign _zz_222_ = (IBusSimplePlugin_pending_value + _zz_224_);
  assign _zz_223_ = IBusSimplePlugin_pending_inc;
  assign _zz_224_ = {2'd0, _zz_223_};
  assign _zz_225_ = IBusSimplePlugin_pending_dec;
  assign _zz_226_ = {2'd0, _zz_225_};
  assign _zz_227_ = (IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_valid && (IBusSimplePlugin_rspJoin_rspBuffer_discardCounter != (3'b000)));
  assign _zz_228_ = {2'd0, _zz_227_};
  assign _zz_229_ = execute_SRC_LESS;
  assign _zz_230_ = (execute_IS_RVC ? (3'b010) : (3'b100));
  assign _zz_231_ = execute_INSTRUCTION[19 : 15];
  assign _zz_232_ = execute_INSTRUCTION[31 : 20];
  assign _zz_233_ = {execute_INSTRUCTION[31 : 25],execute_INSTRUCTION[11 : 7]};
  assign _zz_234_ = ($signed(_zz_235_) + $signed(_zz_238_));
  assign _zz_235_ = ($signed(_zz_236_) + $signed(_zz_237_));
  assign _zz_236_ = execute_SRC1;
  assign _zz_237_ = (execute_SRC_USE_SUB_LESS ? (~ execute_SRC2) : execute_SRC2);
  assign _zz_238_ = (execute_SRC_USE_SUB_LESS ? _zz_239_ : _zz_240_);
  assign _zz_239_ = 32'h00000001;
  assign _zz_240_ = 32'h0;
  assign _zz_241_ = memory_MulDivIterativePlugin_mul_counter_willIncrement;
  assign _zz_242_ = {4'd0, _zz_241_};
  assign _zz_243_ = (_zz_244_ + _zz_251_);
  assign _zz_244_ = (_zz_246_ + _zz_248_);
  assign _zz_245_ = (memory_MulDivIterativePlugin_rs2[0] ? memory_MulDivIterativePlugin_rs1 : 33'h0);
  assign _zz_246_ = {{2{_zz_245_[32]}}, _zz_245_};
  assign _zz_247_ = (memory_MulDivIterativePlugin_rs2[1] ? _zz_249_ : 34'h0);
  assign _zz_248_ = {{1{_zz_247_[33]}}, _zz_247_};
  assign _zz_249_ = ({1'd0,memory_MulDivIterativePlugin_rs1} <<< 1);
  assign _zz_250_ = _zz_252_;
  assign _zz_251_ = {{2{_zz_250_[32]}}, _zz_250_};
  assign _zz_252_ = (memory_MulDivIterativePlugin_accumulator >>> 32);
  assign _zz_253_ = memory_MulDivIterativePlugin_div_counter_willIncrement;
  assign _zz_254_ = {4'd0, _zz_253_};
  assign _zz_255_ = {1'd0, memory_MulDivIterativePlugin_rs2};
  assign _zz_256_ = memory_MulDivIterativePlugin_div_stage_0_remainderMinusDenominator[31:0];
  assign _zz_257_ = memory_MulDivIterativePlugin_div_stage_0_remainderShifted[31:0];
  assign _zz_258_ = {_zz_139_,(! memory_MulDivIterativePlugin_div_stage_0_remainderMinusDenominator[32])};
  assign _zz_259_ = {1'd0, memory_MulDivIterativePlugin_rs2};
  assign _zz_260_ = memory_MulDivIterativePlugin_div_stage_1_remainderMinusDenominator[31:0];
  assign _zz_261_ = memory_MulDivIterativePlugin_div_stage_1_remainderShifted[31:0];
  assign _zz_262_ = {memory_MulDivIterativePlugin_div_stage_0_outNumerator,(! memory_MulDivIterativePlugin_div_stage_1_remainderMinusDenominator[32])};
  assign _zz_263_ = _zz_264_;
  assign _zz_264_ = _zz_265_;
  assign _zz_265_ = ({1'b0,(memory_MulDivIterativePlugin_div_needRevert ? (~ _zz_140_) : _zz_140_)} + _zz_267_);
  assign _zz_266_ = memory_MulDivIterativePlugin_div_needRevert;
  assign _zz_267_ = {32'd0, _zz_266_};
  assign _zz_268_ = _zz_142_;
  assign _zz_269_ = {32'd0, _zz_268_};
  assign _zz_270_ = _zz_141_;
  assign _zz_271_ = {31'd0, _zz_270_};
  assign _zz_272_ = {{{execute_INSTRUCTION[31],execute_INSTRUCTION[19 : 12]},execute_INSTRUCTION[20]},execute_INSTRUCTION[30 : 21]};
  assign _zz_273_ = execute_INSTRUCTION[31 : 20];
  assign _zz_274_ = {{{execute_INSTRUCTION[31],execute_INSTRUCTION[7]},execute_INSTRUCTION[30 : 25]},execute_INSTRUCTION[11 : 8]};
  assign _zz_275_ = execute_CsrPlugin_writeData[7 : 7];
  assign _zz_276_ = execute_CsrPlugin_writeData[3 : 3];
  assign _zz_277_ = execute_CsrPlugin_writeData[3 : 3];
  assign _zz_278_ = execute_CsrPlugin_writeData[11 : 11];
  assign _zz_279_ = execute_CsrPlugin_writeData[7 : 7];
  assign _zz_280_ = execute_CsrPlugin_writeData[3 : 3];
  assign _zz_281_ = 1'b1;
  assign _zz_282_ = 1'b1;
  assign _zz_283_ = (_zz_60_[11 : 10] == (2'b01));
  assign _zz_284_ = ((_zz_60_[11 : 10] == (2'b11)) && (_zz_60_[6 : 5] == (2'b00)));
  assign _zz_285_ = 7'h0;
  assign _zz_286_ = _zz_60_[6 : 2];
  assign _zz_287_ = _zz_60_[12];
  assign _zz_288_ = _zz_60_[11 : 7];
  assign _zz_289_ = (decode_INSTRUCTION & 32'h00000044);
  assign _zz_290_ = 32'h0;
  assign _zz_291_ = ((decode_INSTRUCTION & 32'h00000018) == 32'h0);
  assign _zz_292_ = _zz_104_;
  assign _zz_293_ = ((decode_INSTRUCTION & _zz_302_) == 32'h00001000);
  assign _zz_294_ = ((decode_INSTRUCTION & 32'h00000070) == 32'h00000020);
  assign _zz_295_ = _zz_110_;
  assign _zz_296_ = ((decode_INSTRUCTION & _zz_303_) == 32'h0);
  assign _zz_297_ = {(_zz_304_ == _zz_305_),(_zz_306_ == _zz_307_)};
  assign _zz_298_ = (2'b00);
  assign _zz_299_ = ((_zz_308_ == _zz_309_) != (1'b0));
  assign _zz_300_ = (_zz_310_ != (1'b0));
  assign _zz_301_ = {(_zz_311_ != _zz_312_),{_zz_313_,{_zz_314_,_zz_315_}}};
  assign _zz_302_ = 32'h00005004;
  assign _zz_303_ = 32'h00000020;
  assign _zz_304_ = (decode_INSTRUCTION & 32'h00001050);
  assign _zz_305_ = 32'h00001050;
  assign _zz_306_ = (decode_INSTRUCTION & 32'h00002050);
  assign _zz_307_ = 32'h00002050;
  assign _zz_308_ = (decode_INSTRUCTION & 32'h00000064);
  assign _zz_309_ = 32'h00000024;
  assign _zz_310_ = ((decode_INSTRUCTION & 32'h00001000) == 32'h00001000);
  assign _zz_311_ = _zz_106_;
  assign _zz_312_ = (1'b0);
  assign _zz_313_ = ({_zz_110_,{_zz_316_,_zz_317_}} != (3'b000));
  assign _zz_314_ = ({_zz_318_,_zz_319_} != (2'b00));
  assign _zz_315_ = {(_zz_320_ != (1'b0)),{(_zz_321_ != _zz_322_),{_zz_323_,{_zz_324_,_zz_325_}}}};
  assign _zz_316_ = ((decode_INSTRUCTION & 32'h00000030) == 32'h00000010);
  assign _zz_317_ = ((decode_INSTRUCTION & 32'h02000060) == 32'h00000020);
  assign _zz_318_ = ((decode_INSTRUCTION & 32'h00000050) == 32'h00000040);
  assign _zz_319_ = ((decode_INSTRUCTION & 32'h00003040) == 32'h00000040);
  assign _zz_320_ = ((decode_INSTRUCTION & 32'h00000020) == 32'h00000020);
  assign _zz_321_ = ((decode_INSTRUCTION & _zz_326_) == 32'h0);
  assign _zz_322_ = (1'b0);
  assign _zz_323_ = ({_zz_109_,{_zz_327_,_zz_328_}} != 6'h0);
  assign _zz_324_ = ({_zz_329_,_zz_330_} != (2'b00));
  assign _zz_325_ = {(_zz_331_ != _zz_332_),{_zz_333_,{_zz_334_,_zz_335_}}};
  assign _zz_326_ = 32'h00000058;
  assign _zz_327_ = ((decode_INSTRUCTION & _zz_336_) == 32'h00001010);
  assign _zz_328_ = {(_zz_337_ == _zz_338_),{_zz_339_,{_zz_340_,_zz_341_}}};
  assign _zz_329_ = ((decode_INSTRUCTION & _zz_342_) == 32'h00002000);
  assign _zz_330_ = ((decode_INSTRUCTION & _zz_343_) == 32'h00001000);
  assign _zz_331_ = {_zz_109_,(_zz_344_ == _zz_345_)};
  assign _zz_332_ = (2'b00);
  assign _zz_333_ = ((_zz_346_ == _zz_347_) != (1'b0));
  assign _zz_334_ = ({_zz_348_,_zz_349_} != (3'b000));
  assign _zz_335_ = {(_zz_350_ != _zz_351_),{_zz_352_,{_zz_353_,_zz_354_}}};
  assign _zz_336_ = 32'h00001010;
  assign _zz_337_ = (decode_INSTRUCTION & 32'h00002010);
  assign _zz_338_ = 32'h00002010;
  assign _zz_339_ = ((decode_INSTRUCTION & _zz_355_) == 32'h00000010);
  assign _zz_340_ = (_zz_356_ == _zz_357_);
  assign _zz_341_ = (_zz_358_ == _zz_359_);
  assign _zz_342_ = 32'h00002010;
  assign _zz_343_ = 32'h00005000;
  assign _zz_344_ = (decode_INSTRUCTION & 32'h0000001c);
  assign _zz_345_ = 32'h00000004;
  assign _zz_346_ = (decode_INSTRUCTION & 32'h00000058);
  assign _zz_347_ = 32'h00000040;
  assign _zz_348_ = (_zz_360_ == _zz_361_);
  assign _zz_349_ = {_zz_362_,_zz_363_};
  assign _zz_350_ = {_zz_364_,_zz_108_};
  assign _zz_351_ = (2'b00);
  assign _zz_352_ = ({_zz_365_,_zz_366_} != (2'b00));
  assign _zz_353_ = (_zz_367_ != _zz_368_);
  assign _zz_354_ = {_zz_369_,{_zz_370_,_zz_371_}};
  assign _zz_355_ = 32'h00000050;
  assign _zz_356_ = (decode_INSTRUCTION & 32'h0000000c);
  assign _zz_357_ = 32'h00000004;
  assign _zz_358_ = (decode_INSTRUCTION & 32'h00000028);
  assign _zz_359_ = 32'h0;
  assign _zz_360_ = (decode_INSTRUCTION & 32'h00000044);
  assign _zz_361_ = 32'h00000040;
  assign _zz_362_ = ((decode_INSTRUCTION & 32'h00002014) == 32'h00002010);
  assign _zz_363_ = ((decode_INSTRUCTION & 32'h40000034) == 32'h40000030);
  assign _zz_364_ = ((decode_INSTRUCTION & 32'h00000014) == 32'h00000004);
  assign _zz_365_ = ((decode_INSTRUCTION & _zz_372_) == 32'h00000004);
  assign _zz_366_ = _zz_108_;
  assign _zz_367_ = ((decode_INSTRUCTION & _zz_373_) == 32'h00000050);
  assign _zz_368_ = (1'b0);
  assign _zz_369_ = ({_zz_374_,_zz_375_} != (2'b00));
  assign _zz_370_ = ({_zz_376_,_zz_377_} != (3'b000));
  assign _zz_371_ = {(_zz_378_ != _zz_379_),{_zz_380_,{_zz_381_,_zz_382_}}};
  assign _zz_372_ = 32'h00000044;
  assign _zz_373_ = 32'h00003050;
  assign _zz_374_ = ((decode_INSTRUCTION & 32'h00007034) == 32'h00005010);
  assign _zz_375_ = ((decode_INSTRUCTION & 32'h02007064) == 32'h00005020);
  assign _zz_376_ = ((decode_INSTRUCTION & _zz_383_) == 32'h40001010);
  assign _zz_377_ = {(_zz_384_ == _zz_385_),(_zz_386_ == _zz_387_)};
  assign _zz_378_ = {(_zz_388_ == _zz_389_),(_zz_390_ == _zz_391_)};
  assign _zz_379_ = (2'b00);
  assign _zz_380_ = ({_zz_107_,_zz_105_} != (2'b00));
  assign _zz_381_ = (_zz_392_ != (1'b0));
  assign _zz_382_ = {(_zz_393_ != _zz_394_),{_zz_395_,{_zz_396_,_zz_397_}}};
  assign _zz_383_ = 32'h40003054;
  assign _zz_384_ = (decode_INSTRUCTION & 32'h00007034);
  assign _zz_385_ = 32'h00001010;
  assign _zz_386_ = (decode_INSTRUCTION & 32'h02007054);
  assign _zz_387_ = 32'h00001010;
  assign _zz_388_ = (decode_INSTRUCTION & 32'h00000034);
  assign _zz_389_ = 32'h00000020;
  assign _zz_390_ = (decode_INSTRUCTION & 32'h00000064);
  assign _zz_391_ = 32'h00000020;
  assign _zz_392_ = ((decode_INSTRUCTION & 32'h0) == 32'h0);
  assign _zz_393_ = {_zz_107_,{_zz_106_,_zz_105_}};
  assign _zz_394_ = (3'b000);
  assign _zz_395_ = (((decode_INSTRUCTION & _zz_398_) == 32'h00004000) != (1'b0));
  assign _zz_396_ = (_zz_104_ != (1'b0));
  assign _zz_397_ = {(_zz_399_ != (1'b0)),(_zz_400_ != (1'b0))};
  assign _zz_398_ = 32'h00004004;
  assign _zz_399_ = ((decode_INSTRUCTION & 32'h02004074) == 32'h02000030);
  assign _zz_400_ = ((decode_INSTRUCTION & 32'h02004064) == 32'h02004020);
  always @ (posedge clk) begin
    if(_zz_281_) begin
      _zz_161_ <= RegFilePlugin_regFile[decode_RegFilePlugin_regFileReadAddress1];
    end
  end

  always @ (posedge clk) begin
    if(_zz_282_) begin
      _zz_162_ <= RegFilePlugin_regFile[decode_RegFilePlugin_regFileReadAddress2];
    end
  end

  always @ (posedge clk) begin
    if(_zz_36_) begin
      RegFilePlugin_regFile[lastStageRegFileWrite_payload_address] <= lastStageRegFileWrite_payload_data;
    end
  end

  StreamFifoLowLatency IBusSimplePlugin_rspJoin_rspBuffer_c ( 
    .io_push_valid            (iBus_rsp_valid                                                  ), //i
    .io_push_ready            (IBusSimplePlugin_rspJoin_rspBuffer_c_io_push_ready              ), //o
    .io_push_payload_error    (iBus_rsp_payload_error                                          ), //i
    .io_push_payload_inst     (iBus_rsp_payload_inst[31:0]                                     ), //i
    .io_pop_valid             (IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_valid               ), //o
    .io_pop_ready             (_zz_159_                                                        ), //i
    .io_pop_payload_error     (IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_error       ), //o
    .io_pop_payload_inst      (IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_inst[31:0]  ), //o
    .io_flush                 (_zz_160_                                                        ), //i
    .io_occupancy             (IBusSimplePlugin_rspJoin_rspBuffer_c_io_occupancy               ), //o
    .clk                      (clk                                                             ), //i
    .reset                    (reset                                                           )  //i
  );
  `ifndef SYNTHESIS
  always @(*) begin
    case(decode_ALU_BITWISE_CTRL)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : decode_ALU_BITWISE_CTRL_string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : decode_ALU_BITWISE_CTRL_string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : decode_ALU_BITWISE_CTRL_string = "AND_1";
      default : decode_ALU_BITWISE_CTRL_string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_1_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_1__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_1__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_1__string = "AND_1";
      default : _zz_1__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_2_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_2__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_2__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_2__string = "AND_1";
      default : _zz_2__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_3_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_3__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_3__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_3__string = "AND_1";
      default : _zz_3__string = "?????";
    endcase
  end
  always @(*) begin
    case(decode_SRC2_CTRL)
      `Src2CtrlEnum_defaultEncoding_RS : decode_SRC2_CTRL_string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : decode_SRC2_CTRL_string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : decode_SRC2_CTRL_string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : decode_SRC2_CTRL_string = "PC ";
      default : decode_SRC2_CTRL_string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_4_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_4__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_4__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_4__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_4__string = "PC ";
      default : _zz_4__string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_5_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_5__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_5__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_5__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_5__string = "PC ";
      default : _zz_5__string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_6_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_6__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_6__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_6__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_6__string = "PC ";
      default : _zz_6__string = "???";
    endcase
  end
  always @(*) begin
    case(decode_SHIFT_CTRL)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : decode_SHIFT_CTRL_string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : decode_SHIFT_CTRL_string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : decode_SHIFT_CTRL_string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : decode_SHIFT_CTRL_string = "SRA_1    ";
      default : decode_SHIFT_CTRL_string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_7_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_7__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_7__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_7__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_7__string = "SRA_1    ";
      default : _zz_7__string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_8_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_8__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_8__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_8__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_8__string = "SRA_1    ";
      default : _zz_8__string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_9_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_9__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_9__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_9__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_9__string = "SRA_1    ";
      default : _zz_9__string = "?????????";
    endcase
  end
  always @(*) begin
    case(decode_SRC1_CTRL)
      `Src1CtrlEnum_defaultEncoding_RS : decode_SRC1_CTRL_string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : decode_SRC1_CTRL_string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : decode_SRC1_CTRL_string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : decode_SRC1_CTRL_string = "URS1        ";
      default : decode_SRC1_CTRL_string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_10_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_10__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_10__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_10__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_10__string = "URS1        ";
      default : _zz_10__string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_11_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_11__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_11__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_11__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_11__string = "URS1        ";
      default : _zz_11__string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_12_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_12__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_12__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_12__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_12__string = "URS1        ";
      default : _zz_12__string = "????????????";
    endcase
  end
  always @(*) begin
    case(decode_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_INC : decode_BRANCH_CTRL_string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : decode_BRANCH_CTRL_string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : decode_BRANCH_CTRL_string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : decode_BRANCH_CTRL_string = "JALR";
      default : decode_BRANCH_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_13_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_13__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_13__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_13__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_13__string = "JALR";
      default : _zz_13__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_14_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_14__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_14__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_14__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_14__string = "JALR";
      default : _zz_14__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_15_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_15__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_15__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_15__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_15__string = "JALR";
      default : _zz_15__string = "????";
    endcase
  end
  always @(*) begin
    case(decode_ALU_CTRL)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : decode_ALU_CTRL_string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : decode_ALU_CTRL_string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : decode_ALU_CTRL_string = "BITWISE ";
      default : decode_ALU_CTRL_string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_16_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_16__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_16__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_16__string = "BITWISE ";
      default : _zz_16__string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_17_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_17__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_17__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_17__string = "BITWISE ";
      default : _zz_17__string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_18_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_18__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_18__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_18__string = "BITWISE ";
      default : _zz_18__string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_19_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_19__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_19__string = "XRET";
      default : _zz_19__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_20_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_20__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_20__string = "XRET";
      default : _zz_20__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_21_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_21__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_21__string = "XRET";
      default : _zz_21__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_22_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_22__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_22__string = "XRET";
      default : _zz_22__string = "????";
    endcase
  end
  always @(*) begin
    case(decode_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : decode_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : decode_ENV_CTRL_string = "XRET";
      default : decode_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_23_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_23__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_23__string = "XRET";
      default : _zz_23__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_24_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_24__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_24__string = "XRET";
      default : _zz_24__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_25_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_25__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_25__string = "XRET";
      default : _zz_25__string = "????";
    endcase
  end
  always @(*) begin
    case(execute_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_INC : execute_BRANCH_CTRL_string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : execute_BRANCH_CTRL_string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : execute_BRANCH_CTRL_string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : execute_BRANCH_CTRL_string = "JALR";
      default : execute_BRANCH_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_26_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_26__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_26__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_26__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_26__string = "JALR";
      default : _zz_26__string = "????";
    endcase
  end
  always @(*) begin
    case(execute_SHIFT_CTRL)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : execute_SHIFT_CTRL_string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : execute_SHIFT_CTRL_string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : execute_SHIFT_CTRL_string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : execute_SHIFT_CTRL_string = "SRA_1    ";
      default : execute_SHIFT_CTRL_string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_27_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_27__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_27__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_27__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_27__string = "SRA_1    ";
      default : _zz_27__string = "?????????";
    endcase
  end
  always @(*) begin
    case(execute_SRC2_CTRL)
      `Src2CtrlEnum_defaultEncoding_RS : execute_SRC2_CTRL_string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : execute_SRC2_CTRL_string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : execute_SRC2_CTRL_string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : execute_SRC2_CTRL_string = "PC ";
      default : execute_SRC2_CTRL_string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_29_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_29__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_29__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_29__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_29__string = "PC ";
      default : _zz_29__string = "???";
    endcase
  end
  always @(*) begin
    case(execute_SRC1_CTRL)
      `Src1CtrlEnum_defaultEncoding_RS : execute_SRC1_CTRL_string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : execute_SRC1_CTRL_string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : execute_SRC1_CTRL_string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : execute_SRC1_CTRL_string = "URS1        ";
      default : execute_SRC1_CTRL_string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_30_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_30__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_30__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_30__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_30__string = "URS1        ";
      default : _zz_30__string = "????????????";
    endcase
  end
  always @(*) begin
    case(execute_ALU_CTRL)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : execute_ALU_CTRL_string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : execute_ALU_CTRL_string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : execute_ALU_CTRL_string = "BITWISE ";
      default : execute_ALU_CTRL_string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_31_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_31__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_31__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_31__string = "BITWISE ";
      default : _zz_31__string = "????????";
    endcase
  end
  always @(*) begin
    case(execute_ALU_BITWISE_CTRL)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : execute_ALU_BITWISE_CTRL_string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : execute_ALU_BITWISE_CTRL_string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : execute_ALU_BITWISE_CTRL_string = "AND_1";
      default : execute_ALU_BITWISE_CTRL_string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_32_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_32__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_32__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_32__string = "AND_1";
      default : _zz_32__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_37_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_37__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_37__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_37__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_37__string = "PC ";
      default : _zz_37__string = "???";
    endcase
  end
  always @(*) begin
    case(_zz_38_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_38__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_38__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_38__string = "AND_1";
      default : _zz_38__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_39_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_39__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_39__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_39__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_39__string = "JALR";
      default : _zz_39__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_40_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_40__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_40__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_40__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_40__string = "URS1        ";
      default : _zz_40__string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_41_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_41__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_41__string = "XRET";
      default : _zz_41__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_42_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_42__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_42__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_42__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_42__string = "SRA_1    ";
      default : _zz_42__string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_43_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_43__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_43__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_43__string = "BITWISE ";
      default : _zz_43__string = "????????";
    endcase
  end
  always @(*) begin
    case(memory_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : memory_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : memory_ENV_CTRL_string = "XRET";
      default : memory_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_45_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_45__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_45__string = "XRET";
      default : _zz_45__string = "????";
    endcase
  end
  always @(*) begin
    case(execute_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : execute_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : execute_ENV_CTRL_string = "XRET";
      default : execute_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_46_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_46__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_46__string = "XRET";
      default : _zz_46__string = "????";
    endcase
  end
  always @(*) begin
    case(writeBack_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : writeBack_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : writeBack_ENV_CTRL_string = "XRET";
      default : writeBack_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_47_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_47__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_47__string = "XRET";
      default : _zz_47__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_111_)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : _zz_111__string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : _zz_111__string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : _zz_111__string = "BITWISE ";
      default : _zz_111__string = "????????";
    endcase
  end
  always @(*) begin
    case(_zz_112_)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : _zz_112__string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : _zz_112__string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : _zz_112__string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : _zz_112__string = "SRA_1    ";
      default : _zz_112__string = "?????????";
    endcase
  end
  always @(*) begin
    case(_zz_113_)
      `EnvCtrlEnum_defaultEncoding_NONE : _zz_113__string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : _zz_113__string = "XRET";
      default : _zz_113__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_114_)
      `Src1CtrlEnum_defaultEncoding_RS : _zz_114__string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : _zz_114__string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : _zz_114__string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : _zz_114__string = "URS1        ";
      default : _zz_114__string = "????????????";
    endcase
  end
  always @(*) begin
    case(_zz_115_)
      `BranchCtrlEnum_defaultEncoding_INC : _zz_115__string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : _zz_115__string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : _zz_115__string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : _zz_115__string = "JALR";
      default : _zz_115__string = "????";
    endcase
  end
  always @(*) begin
    case(_zz_116_)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : _zz_116__string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : _zz_116__string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : _zz_116__string = "AND_1";
      default : _zz_116__string = "?????";
    endcase
  end
  always @(*) begin
    case(_zz_117_)
      `Src2CtrlEnum_defaultEncoding_RS : _zz_117__string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : _zz_117__string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : _zz_117__string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : _zz_117__string = "PC ";
      default : _zz_117__string = "???";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : decode_to_execute_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : decode_to_execute_ENV_CTRL_string = "XRET";
      default : decode_to_execute_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(execute_to_memory_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : execute_to_memory_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : execute_to_memory_ENV_CTRL_string = "XRET";
      default : execute_to_memory_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(memory_to_writeBack_ENV_CTRL)
      `EnvCtrlEnum_defaultEncoding_NONE : memory_to_writeBack_ENV_CTRL_string = "NONE";
      `EnvCtrlEnum_defaultEncoding_XRET : memory_to_writeBack_ENV_CTRL_string = "XRET";
      default : memory_to_writeBack_ENV_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_ALU_CTRL)
      `AluCtrlEnum_defaultEncoding_ADD_SUB : decode_to_execute_ALU_CTRL_string = "ADD_SUB ";
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : decode_to_execute_ALU_CTRL_string = "SLT_SLTU";
      `AluCtrlEnum_defaultEncoding_BITWISE : decode_to_execute_ALU_CTRL_string = "BITWISE ";
      default : decode_to_execute_ALU_CTRL_string = "????????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_INC : decode_to_execute_BRANCH_CTRL_string = "INC ";
      `BranchCtrlEnum_defaultEncoding_B : decode_to_execute_BRANCH_CTRL_string = "B   ";
      `BranchCtrlEnum_defaultEncoding_JAL : decode_to_execute_BRANCH_CTRL_string = "JAL ";
      `BranchCtrlEnum_defaultEncoding_JALR : decode_to_execute_BRANCH_CTRL_string = "JALR";
      default : decode_to_execute_BRANCH_CTRL_string = "????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_SRC1_CTRL)
      `Src1CtrlEnum_defaultEncoding_RS : decode_to_execute_SRC1_CTRL_string = "RS          ";
      `Src1CtrlEnum_defaultEncoding_IMU : decode_to_execute_SRC1_CTRL_string = "IMU         ";
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : decode_to_execute_SRC1_CTRL_string = "PC_INCREMENT";
      `Src1CtrlEnum_defaultEncoding_URS1 : decode_to_execute_SRC1_CTRL_string = "URS1        ";
      default : decode_to_execute_SRC1_CTRL_string = "????????????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_SHIFT_CTRL)
      `ShiftCtrlEnum_defaultEncoding_DISABLE_1 : decode_to_execute_SHIFT_CTRL_string = "DISABLE_1";
      `ShiftCtrlEnum_defaultEncoding_SLL_1 : decode_to_execute_SHIFT_CTRL_string = "SLL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRL_1 : decode_to_execute_SHIFT_CTRL_string = "SRL_1    ";
      `ShiftCtrlEnum_defaultEncoding_SRA_1 : decode_to_execute_SHIFT_CTRL_string = "SRA_1    ";
      default : decode_to_execute_SHIFT_CTRL_string = "?????????";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_SRC2_CTRL)
      `Src2CtrlEnum_defaultEncoding_RS : decode_to_execute_SRC2_CTRL_string = "RS ";
      `Src2CtrlEnum_defaultEncoding_IMI : decode_to_execute_SRC2_CTRL_string = "IMI";
      `Src2CtrlEnum_defaultEncoding_IMS : decode_to_execute_SRC2_CTRL_string = "IMS";
      `Src2CtrlEnum_defaultEncoding_PC : decode_to_execute_SRC2_CTRL_string = "PC ";
      default : decode_to_execute_SRC2_CTRL_string = "???";
    endcase
  end
  always @(*) begin
    case(decode_to_execute_ALU_BITWISE_CTRL)
      `AluBitwiseCtrlEnum_defaultEncoding_XOR_1 : decode_to_execute_ALU_BITWISE_CTRL_string = "XOR_1";
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : decode_to_execute_ALU_BITWISE_CTRL_string = "OR_1 ";
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : decode_to_execute_ALU_BITWISE_CTRL_string = "AND_1";
      default : decode_to_execute_ALU_BITWISE_CTRL_string = "?????";
    endcase
  end
  `endif

  assign decode_ALU_BITWISE_CTRL = _zz_1_;
  assign _zz_2_ = _zz_3_;
  assign decode_MEMORY_ENABLE = _zz_193_[0];
  assign decode_SRC2_CTRL = _zz_4_;
  assign _zz_5_ = _zz_6_;
  assign writeBack_FORMAL_PC_NEXT = memory_to_writeBack_FORMAL_PC_NEXT;
  assign memory_FORMAL_PC_NEXT = execute_to_memory_FORMAL_PC_NEXT;
  assign execute_FORMAL_PC_NEXT = decode_to_execute_FORMAL_PC_NEXT;
  assign decode_FORMAL_PC_NEXT = (decode_PC + _zz_195_);
  assign decode_CSR_READ_OPCODE = (decode_INSTRUCTION[13 : 7] != 7'h20);
  assign decode_CSR_WRITE_OPCODE = (! (((decode_INSTRUCTION[14 : 13] == (2'b01)) && (decode_INSTRUCTION[19 : 15] == 5'h0)) || ((decode_INSTRUCTION[14 : 13] == (2'b11)) && (decode_INSTRUCTION[19 : 15] == 5'h0))));
  assign decode_SHIFT_CTRL = _zz_7_;
  assign _zz_8_ = _zz_9_;
  assign decode_IS_MUL = _zz_196_[0];
  assign decode_MEMORY_STORE = _zz_197_[0];
  assign decode_SRC1_CTRL = _zz_10_;
  assign _zz_11_ = _zz_12_;
  assign decode_IS_CSR = _zz_198_[0];
  assign decode_BYPASSABLE_EXECUTE_STAGE = _zz_199_[0];
  assign writeBack_REGFILE_WRITE_DATA = memory_to_writeBack_REGFILE_WRITE_DATA;
  assign memory_REGFILE_WRITE_DATA = execute_to_memory_REGFILE_WRITE_DATA;
  assign execute_REGFILE_WRITE_DATA = _zz_119_;
  assign decode_IS_RS1_SIGNED = _zz_200_[0];
  assign decode_BRANCH_CTRL = _zz_13_;
  assign _zz_14_ = _zz_15_;
  assign execute_BYPASSABLE_MEMORY_STAGE = decode_to_execute_BYPASSABLE_MEMORY_STAGE;
  assign decode_BYPASSABLE_MEMORY_STAGE = _zz_201_[0];
  assign memory_PC = execute_to_memory_PC;
  assign decode_ALU_CTRL = _zz_16_;
  assign _zz_17_ = _zz_18_;
  assign decode_SRC2_FORCE_ZERO = (decode_SRC_ADD_ZERO && (! decode_SRC_USE_SUB_LESS));
  assign _zz_19_ = _zz_20_;
  assign _zz_21_ = _zz_22_;
  assign decode_ENV_CTRL = _zz_23_;
  assign _zz_24_ = _zz_25_;
  assign decode_SRC_LESS_UNSIGNED = _zz_202_[0];
  assign decode_IS_RS2_SIGNED = _zz_203_[0];
  assign decode_IS_DIV = _zz_204_[0];
  assign execute_MEMORY_ADDRESS_LOW = dBus_cmd_payload_address[1 : 0];
  assign execute_BRANCH_CALC = {execute_BranchPlugin_branchAdder[31 : 1],(1'b0)};
  assign execute_BRANCH_DO = _zz_146_;
  assign execute_PC = decode_to_execute_PC;
  assign execute_BRANCH_CTRL = _zz_26_;
  assign execute_IS_RS1_SIGNED = decode_to_execute_IS_RS1_SIGNED;
  assign execute_RS1 = decode_to_execute_RS1;
  assign execute_IS_DIV = decode_to_execute_IS_DIV;
  assign execute_IS_MUL = decode_to_execute_IS_MUL;
  assign execute_IS_RS2_SIGNED = decode_to_execute_IS_RS2_SIGNED;
  assign memory_IS_DIV = execute_to_memory_IS_DIV;
  assign memory_IS_MUL = execute_to_memory_IS_MUL;
  assign decode_RS2_USE = _zz_205_[0];
  assign decode_RS1_USE = _zz_206_[0];
  assign execute_REGFILE_WRITE_VALID = decode_to_execute_REGFILE_WRITE_VALID;
  assign execute_BYPASSABLE_EXECUTE_STAGE = decode_to_execute_BYPASSABLE_EXECUTE_STAGE;
  assign memory_REGFILE_WRITE_VALID = execute_to_memory_REGFILE_WRITE_VALID;
  assign memory_BYPASSABLE_MEMORY_STAGE = execute_to_memory_BYPASSABLE_MEMORY_STAGE;
  assign writeBack_REGFILE_WRITE_VALID = memory_to_writeBack_REGFILE_WRITE_VALID;
  always @ (*) begin
    decode_RS2 = decode_RegFilePlugin_rs2Data;
    if(_zz_130_)begin
      if((_zz_131_ == decode_INSTRUCTION[24 : 20]))begin
        decode_RS2 = _zz_132_;
      end
    end
    if(_zz_163_)begin
      if(_zz_164_)begin
        if(_zz_134_)begin
          decode_RS2 = _zz_33_;
        end
      end
    end
    if(_zz_165_)begin
      if(memory_BYPASSABLE_MEMORY_STAGE)begin
        if(_zz_136_)begin
          decode_RS2 = _zz_48_;
        end
      end
    end
    if(_zz_166_)begin
      if(execute_BYPASSABLE_EXECUTE_STAGE)begin
        if(_zz_138_)begin
          decode_RS2 = _zz_44_;
        end
      end
    end
  end

  always @ (*) begin
    decode_RS1 = decode_RegFilePlugin_rs1Data;
    if(_zz_130_)begin
      if((_zz_131_ == decode_INSTRUCTION[19 : 15]))begin
        decode_RS1 = _zz_132_;
      end
    end
    if(_zz_163_)begin
      if(_zz_164_)begin
        if(_zz_133_)begin
          decode_RS1 = _zz_33_;
        end
      end
    end
    if(_zz_165_)begin
      if(memory_BYPASSABLE_MEMORY_STAGE)begin
        if(_zz_135_)begin
          decode_RS1 = _zz_48_;
        end
      end
    end
    if(_zz_166_)begin
      if(execute_BYPASSABLE_EXECUTE_STAGE)begin
        if(_zz_137_)begin
          decode_RS1 = _zz_44_;
        end
      end
    end
  end

  assign execute_SHIFT_RIGHT = _zz_208_;
  assign execute_SHIFT_CTRL = _zz_27_;
  assign execute_SRC_LESS_UNSIGNED = decode_to_execute_SRC_LESS_UNSIGNED;
  assign execute_SRC2_FORCE_ZERO = decode_to_execute_SRC2_FORCE_ZERO;
  assign execute_SRC_USE_SUB_LESS = decode_to_execute_SRC_USE_SUB_LESS;
  assign _zz_28_ = execute_PC;
  assign execute_SRC2_CTRL = _zz_29_;
  assign execute_IS_RVC = decode_to_execute_IS_RVC;
  assign execute_SRC1_CTRL = _zz_30_;
  assign decode_SRC_USE_SUB_LESS = _zz_210_[0];
  assign decode_SRC_ADD_ZERO = _zz_211_[0];
  assign execute_SRC_ADD_SUB = execute_SrcPlugin_addSub;
  assign execute_SRC_LESS = execute_SrcPlugin_less;
  assign execute_ALU_CTRL = _zz_31_;
  assign execute_SRC2 = _zz_125_;
  assign execute_ALU_BITWISE_CTRL = _zz_32_;
  assign _zz_33_ = writeBack_REGFILE_WRITE_DATA;
  assign _zz_34_ = writeBack_INSTRUCTION;
  assign _zz_35_ = writeBack_REGFILE_WRITE_VALID;
  always @ (*) begin
    _zz_36_ = 1'b0;
    if(lastStageRegFileWrite_valid)begin
      _zz_36_ = 1'b1;
    end
  end

  assign decode_INSTRUCTION_ANTICIPATED = (decode_arbitration_isStuck ? decode_INSTRUCTION : IBusSimplePlugin_decompressor_output_payload_rsp_inst);
  always @ (*) begin
    decode_REGFILE_WRITE_VALID = _zz_212_[0];
    if((decode_INSTRUCTION[11 : 7] == 5'h0))begin
      decode_REGFILE_WRITE_VALID = 1'b0;
    end
    if(decode_INSTRUCTION[11])begin
      decode_REGFILE_WRITE_VALID = 1'b0;
    end
  end

  always @ (*) begin
    _zz_44_ = execute_REGFILE_WRITE_DATA;
    if(_zz_167_)begin
      _zz_44_ = execute_CsrPlugin_readData;
    end
    if(execute_arbitration_isValid)begin
      case(execute_SHIFT_CTRL)
        `ShiftCtrlEnum_defaultEncoding_SLL_1 : begin
          _zz_44_ = _zz_127_;
        end
        `ShiftCtrlEnum_defaultEncoding_SRL_1, `ShiftCtrlEnum_defaultEncoding_SRA_1 : begin
          _zz_44_ = execute_SHIFT_RIGHT;
        end
        default : begin
        end
      endcase
    end
  end

  assign execute_SRC1 = _zz_120_;
  assign execute_CSR_READ_OPCODE = decode_to_execute_CSR_READ_OPCODE;
  assign execute_CSR_WRITE_OPCODE = decode_to_execute_CSR_WRITE_OPCODE;
  assign execute_IS_CSR = decode_to_execute_IS_CSR;
  assign memory_ENV_CTRL = _zz_45_;
  assign execute_ENV_CTRL = _zz_46_;
  assign writeBack_ENV_CTRL = _zz_47_;
  always @ (*) begin
    _zz_48_ = memory_REGFILE_WRITE_DATA;
    if((memory_arbitration_isValid && memory_MEMORY_ENABLE))begin
      _zz_48_ = memory_DBusSimplePlugin_rspFormated;
    end
    if(_zz_168_)begin
      _zz_48_ = ((memory_INSTRUCTION[13 : 12] == (2'b00)) ? memory_MulDivIterativePlugin_accumulator[31 : 0] : memory_MulDivIterativePlugin_accumulator[63 : 32]);
    end
    if(_zz_169_)begin
      _zz_48_ = memory_MulDivIterativePlugin_div_result;
    end
  end

  assign memory_INSTRUCTION = execute_to_memory_INSTRUCTION;
  assign memory_MEMORY_ADDRESS_LOW = execute_to_memory_MEMORY_ADDRESS_LOW;
  assign memory_MEMORY_READ_DATA = dBus_rsp_data;
  assign memory_MEMORY_STORE = execute_to_memory_MEMORY_STORE;
  assign memory_MEMORY_ENABLE = execute_to_memory_MEMORY_ENABLE;
  assign execute_SRC_ADD = execute_SrcPlugin_addSub;
  assign execute_RS2 = decode_to_execute_RS2;
  assign execute_INSTRUCTION = decode_to_execute_INSTRUCTION;
  assign execute_MEMORY_STORE = decode_to_execute_MEMORY_STORE;
  assign execute_MEMORY_ENABLE = decode_to_execute_MEMORY_ENABLE;
  assign execute_ALIGNEMENT_FAULT = 1'b0;
  always @ (*) begin
    _zz_49_ = execute_FORMAL_PC_NEXT;
    if(BranchPlugin_jumpInterface_valid)begin
      _zz_49_ = BranchPlugin_jumpInterface_payload;
    end
  end

  assign decode_PC = IBusSimplePlugin_decodePc_pcReg;
  assign decode_INSTRUCTION = IBusSimplePlugin_injector_decodeInput_payload_rsp_inst;
  assign decode_IS_RVC = IBusSimplePlugin_injector_decodeInput_payload_isRvc;
  assign writeBack_PC = memory_to_writeBack_PC;
  assign writeBack_INSTRUCTION = memory_to_writeBack_INSTRUCTION;
  assign decode_arbitration_haltItself = 1'b0;
  always @ (*) begin
    decode_arbitration_haltByOther = 1'b0;
    if(CsrPlugin_pipelineLiberator_active)begin
      decode_arbitration_haltByOther = 1'b1;
    end
    if(({(writeBack_arbitration_isValid && (writeBack_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET)),{(memory_arbitration_isValid && (memory_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET)),(execute_arbitration_isValid && (execute_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET))}} != (3'b000)))begin
      decode_arbitration_haltByOther = 1'b1;
    end
    if((decode_arbitration_isValid && (_zz_128_ || _zz_129_)))begin
      decode_arbitration_haltByOther = 1'b1;
    end
  end

  always @ (*) begin
    decode_arbitration_removeIt = 1'b0;
    if(decode_arbitration_isFlushed)begin
      decode_arbitration_removeIt = 1'b1;
    end
  end

  assign decode_arbitration_flushIt = 1'b0;
  assign decode_arbitration_flushNext = 1'b0;
  always @ (*) begin
    execute_arbitration_haltItself = 1'b0;
    if(((((execute_arbitration_isValid && execute_MEMORY_ENABLE) && (! dBus_cmd_ready)) && (! execute_DBusSimplePlugin_skipCmd)) && (! _zz_93_)))begin
      execute_arbitration_haltItself = 1'b1;
    end
    if(_zz_167_)begin
      if(execute_CsrPlugin_blockedBySideEffects)begin
        execute_arbitration_haltItself = 1'b1;
      end
    end
  end

  assign execute_arbitration_haltByOther = 1'b0;
  always @ (*) begin
    execute_arbitration_removeIt = 1'b0;
    if(execute_arbitration_isFlushed)begin
      execute_arbitration_removeIt = 1'b1;
    end
  end

  assign execute_arbitration_flushIt = 1'b0;
  always @ (*) begin
    execute_arbitration_flushNext = 1'b0;
    if(BranchPlugin_jumpInterface_valid)begin
      execute_arbitration_flushNext = 1'b1;
    end
  end

  always @ (*) begin
    memory_arbitration_haltItself = 1'b0;
    if((((memory_arbitration_isValid && memory_MEMORY_ENABLE) && (! memory_MEMORY_STORE)) && ((! dBus_rsp_ready) || 1'b0)))begin
      memory_arbitration_haltItself = 1'b1;
    end
    if(_zz_168_)begin
      if(((! memory_MulDivIterativePlugin_frontendOk) || (! memory_MulDivIterativePlugin_mul_counter_willOverflowIfInc)))begin
        memory_arbitration_haltItself = 1'b1;
      end
      if(_zz_170_)begin
        memory_arbitration_haltItself = 1'b1;
      end
    end
    if(_zz_169_)begin
      if(((! memory_MulDivIterativePlugin_frontendOk) || (! memory_MulDivIterativePlugin_div_done)))begin
        memory_arbitration_haltItself = 1'b1;
      end
    end
  end

  assign memory_arbitration_haltByOther = 1'b0;
  always @ (*) begin
    memory_arbitration_removeIt = 1'b0;
    if(memory_arbitration_isFlushed)begin
      memory_arbitration_removeIt = 1'b1;
    end
  end

  assign memory_arbitration_flushIt = 1'b0;
  assign memory_arbitration_flushNext = 1'b0;
  assign writeBack_arbitration_haltItself = 1'b0;
  assign writeBack_arbitration_haltByOther = 1'b0;
  always @ (*) begin
    writeBack_arbitration_removeIt = 1'b0;
    if(writeBack_arbitration_isFlushed)begin
      writeBack_arbitration_removeIt = 1'b1;
    end
  end

  assign writeBack_arbitration_flushIt = 1'b0;
  always @ (*) begin
    writeBack_arbitration_flushNext = 1'b0;
    if(_zz_171_)begin
      writeBack_arbitration_flushNext = 1'b1;
    end
    if(_zz_172_)begin
      writeBack_arbitration_flushNext = 1'b1;
    end
  end

  assign lastStageInstruction = writeBack_INSTRUCTION;
  assign lastStagePc = writeBack_PC;
  assign lastStageIsValid = writeBack_arbitration_isValid;
  assign lastStageIsFiring = writeBack_arbitration_isFiring;
  always @ (*) begin
    IBusSimplePlugin_fetcherHalt = 1'b0;
    if(_zz_171_)begin
      IBusSimplePlugin_fetcherHalt = 1'b1;
    end
    if(_zz_172_)begin
      IBusSimplePlugin_fetcherHalt = 1'b1;
    end
  end

  always @ (*) begin
    IBusSimplePlugin_incomingInstruction = 1'b0;
    if((IBusSimplePlugin_iBusRsp_stages_1_input_valid || IBusSimplePlugin_iBusRsp_stages_2_input_valid))begin
      IBusSimplePlugin_incomingInstruction = 1'b1;
    end
    if(IBusSimplePlugin_injector_decodeInput_valid)begin
      IBusSimplePlugin_incomingInstruction = 1'b1;
    end
  end

  assign CsrPlugin_inWfi = 1'b0;
  assign CsrPlugin_thirdPartyWake = 1'b0;
  always @ (*) begin
    CsrPlugin_jumpInterface_valid = 1'b0;
    if(_zz_171_)begin
      CsrPlugin_jumpInterface_valid = 1'b1;
    end
    if(_zz_172_)begin
      CsrPlugin_jumpInterface_valid = 1'b1;
    end
  end

  always @ (*) begin
    CsrPlugin_jumpInterface_payload = 32'h0;
    if(_zz_171_)begin
      CsrPlugin_jumpInterface_payload = {CsrPlugin_xtvec_base,(2'b00)};
    end
    if(_zz_172_)begin
      case(_zz_173_)
        2'b11 : begin
          CsrPlugin_jumpInterface_payload = CsrPlugin_mepc;
        end
        default : begin
        end
      endcase
    end
  end

  assign CsrPlugin_forceMachineWire = 1'b0;
  assign CsrPlugin_allowInterrupts = 1'b1;
  assign CsrPlugin_allowException = 1'b1;
  assign IBusSimplePlugin_externalFlush = ({writeBack_arbitration_flushNext,{memory_arbitration_flushNext,{execute_arbitration_flushNext,decode_arbitration_flushNext}}} != (4'b0000));
  assign IBusSimplePlugin_jump_pcLoad_valid = ({BranchPlugin_jumpInterface_valid,CsrPlugin_jumpInterface_valid} != (2'b00));
  assign _zz_50_ = {BranchPlugin_jumpInterface_valid,CsrPlugin_jumpInterface_valid};
  assign IBusSimplePlugin_jump_pcLoad_payload = (_zz_213_[0] ? CsrPlugin_jumpInterface_payload : BranchPlugin_jumpInterface_payload);
  always @ (*) begin
    IBusSimplePlugin_fetchPc_correction = 1'b0;
    if(IBusSimplePlugin_jump_pcLoad_valid)begin
      IBusSimplePlugin_fetchPc_correction = 1'b1;
    end
  end

  assign IBusSimplePlugin_fetchPc_corrected = (IBusSimplePlugin_fetchPc_correction || IBusSimplePlugin_fetchPc_correctionReg);
  always @ (*) begin
    IBusSimplePlugin_fetchPc_pcRegPropagate = 1'b0;
    if(IBusSimplePlugin_iBusRsp_stages_1_input_ready)begin
      IBusSimplePlugin_fetchPc_pcRegPropagate = 1'b1;
    end
  end

  always @ (*) begin
    IBusSimplePlugin_fetchPc_pc = (IBusSimplePlugin_fetchPc_pcReg + _zz_216_);
    if(IBusSimplePlugin_fetchPc_inc)begin
      IBusSimplePlugin_fetchPc_pc[1] = 1'b0;
    end
    if(IBusSimplePlugin_jump_pcLoad_valid)begin
      IBusSimplePlugin_fetchPc_pc = IBusSimplePlugin_jump_pcLoad_payload;
    end
    IBusSimplePlugin_fetchPc_pc[0] = 1'b0;
  end

  always @ (*) begin
    IBusSimplePlugin_fetchPc_flushed = 1'b0;
    if(IBusSimplePlugin_jump_pcLoad_valid)begin
      IBusSimplePlugin_fetchPc_flushed = 1'b1;
    end
  end

  assign IBusSimplePlugin_fetchPc_output_valid = ((! IBusSimplePlugin_fetcherHalt) && IBusSimplePlugin_fetchPc_booted);
  assign IBusSimplePlugin_fetchPc_output_payload = IBusSimplePlugin_fetchPc_pc;
  always @ (*) begin
    IBusSimplePlugin_decodePc_flushed = 1'b0;
    if(_zz_174_)begin
      IBusSimplePlugin_decodePc_flushed = 1'b1;
    end
  end

  assign IBusSimplePlugin_decodePc_pcPlus = (IBusSimplePlugin_decodePc_pcReg + _zz_218_);
  assign IBusSimplePlugin_decodePc_injectedDecode = 1'b0;
  assign IBusSimplePlugin_iBusRsp_redoFetch = 1'b0;
  assign IBusSimplePlugin_iBusRsp_stages_0_input_valid = IBusSimplePlugin_fetchPc_output_valid;
  assign IBusSimplePlugin_fetchPc_output_ready = IBusSimplePlugin_iBusRsp_stages_0_input_ready;
  assign IBusSimplePlugin_iBusRsp_stages_0_input_payload = IBusSimplePlugin_fetchPc_output_payload;
  assign IBusSimplePlugin_iBusRsp_stages_0_halt = 1'b0;
  assign _zz_51_ = (! IBusSimplePlugin_iBusRsp_stages_0_halt);
  assign IBusSimplePlugin_iBusRsp_stages_0_input_ready = (IBusSimplePlugin_iBusRsp_stages_0_output_ready && _zz_51_);
  assign IBusSimplePlugin_iBusRsp_stages_0_output_valid = (IBusSimplePlugin_iBusRsp_stages_0_input_valid && _zz_51_);
  assign IBusSimplePlugin_iBusRsp_stages_0_output_payload = IBusSimplePlugin_iBusRsp_stages_0_input_payload;
  always @ (*) begin
    IBusSimplePlugin_iBusRsp_stages_1_halt = 1'b0;
    if((IBusSimplePlugin_iBusRsp_stages_1_input_valid && ((! IBusSimplePlugin_cmdFork_canEmit) || (! IBusSimplePlugin_cmd_ready))))begin
      IBusSimplePlugin_iBusRsp_stages_1_halt = 1'b1;
    end
  end

  assign _zz_52_ = (! IBusSimplePlugin_iBusRsp_stages_1_halt);
  assign IBusSimplePlugin_iBusRsp_stages_1_input_ready = (IBusSimplePlugin_iBusRsp_stages_1_output_ready && _zz_52_);
  assign IBusSimplePlugin_iBusRsp_stages_1_output_valid = (IBusSimplePlugin_iBusRsp_stages_1_input_valid && _zz_52_);
  assign IBusSimplePlugin_iBusRsp_stages_1_output_payload = IBusSimplePlugin_iBusRsp_stages_1_input_payload;
  assign IBusSimplePlugin_iBusRsp_stages_2_halt = 1'b0;
  assign _zz_53_ = (! IBusSimplePlugin_iBusRsp_stages_2_halt);
  assign IBusSimplePlugin_iBusRsp_stages_2_input_ready = (IBusSimplePlugin_iBusRsp_stages_2_output_ready && _zz_53_);
  assign IBusSimplePlugin_iBusRsp_stages_2_output_valid = (IBusSimplePlugin_iBusRsp_stages_2_input_valid && _zz_53_);
  assign IBusSimplePlugin_iBusRsp_stages_2_output_payload = IBusSimplePlugin_iBusRsp_stages_2_input_payload;
  assign IBusSimplePlugin_iBusRsp_flush = (IBusSimplePlugin_externalFlush || IBusSimplePlugin_iBusRsp_redoFetch);
  assign IBusSimplePlugin_iBusRsp_stages_0_output_ready = _zz_54_;
  assign _zz_54_ = ((1'b0 && (! _zz_55_)) || IBusSimplePlugin_iBusRsp_stages_1_input_ready);
  assign _zz_55_ = _zz_56_;
  assign IBusSimplePlugin_iBusRsp_stages_1_input_valid = _zz_55_;
  assign IBusSimplePlugin_iBusRsp_stages_1_input_payload = IBusSimplePlugin_fetchPc_pcReg;
  assign IBusSimplePlugin_iBusRsp_stages_1_output_ready = ((1'b0 && (! _zz_57_)) || IBusSimplePlugin_iBusRsp_stages_2_input_ready);
  assign _zz_57_ = _zz_58_;
  assign IBusSimplePlugin_iBusRsp_stages_2_input_valid = _zz_57_;
  assign IBusSimplePlugin_iBusRsp_stages_2_input_payload = _zz_59_;
  always @ (*) begin
    IBusSimplePlugin_iBusRsp_readyForError = 1'b1;
    if(IBusSimplePlugin_injector_decodeInput_valid)begin
      IBusSimplePlugin_iBusRsp_readyForError = 1'b0;
    end
  end

  assign IBusSimplePlugin_decompressor_input_valid = (IBusSimplePlugin_iBusRsp_output_valid && (! IBusSimplePlugin_iBusRsp_redoFetch));
  assign IBusSimplePlugin_decompressor_input_payload_pc = IBusSimplePlugin_iBusRsp_output_payload_pc;
  assign IBusSimplePlugin_decompressor_input_payload_rsp_error = IBusSimplePlugin_iBusRsp_output_payload_rsp_error;
  assign IBusSimplePlugin_decompressor_input_payload_rsp_inst = IBusSimplePlugin_iBusRsp_output_payload_rsp_inst;
  assign IBusSimplePlugin_decompressor_input_payload_isRvc = IBusSimplePlugin_iBusRsp_output_payload_isRvc;
  assign IBusSimplePlugin_iBusRsp_output_ready = IBusSimplePlugin_decompressor_input_ready;
  assign IBusSimplePlugin_decompressor_flushNext = 1'b0;
  assign IBusSimplePlugin_decompressor_consumeCurrent = 1'b0;
  assign IBusSimplePlugin_decompressor_isInputLowRvc = (IBusSimplePlugin_decompressor_input_payload_rsp_inst[1 : 0] != (2'b11));
  assign IBusSimplePlugin_decompressor_isInputHighRvc = (IBusSimplePlugin_decompressor_input_payload_rsp_inst[17 : 16] != (2'b11));
  assign IBusSimplePlugin_decompressor_throw2Bytes = (IBusSimplePlugin_decompressor_throw2BytesReg || IBusSimplePlugin_decompressor_input_payload_pc[1]);
  assign IBusSimplePlugin_decompressor_unaligned = (IBusSimplePlugin_decompressor_throw2Bytes || IBusSimplePlugin_decompressor_bufferValid);
  assign IBusSimplePlugin_decompressor_raw = (IBusSimplePlugin_decompressor_bufferValid ? {IBusSimplePlugin_decompressor_input_payload_rsp_inst[15 : 0],IBusSimplePlugin_decompressor_bufferData} : {IBusSimplePlugin_decompressor_input_payload_rsp_inst[31 : 16],(IBusSimplePlugin_decompressor_throw2Bytes ? IBusSimplePlugin_decompressor_input_payload_rsp_inst[31 : 16] : IBusSimplePlugin_decompressor_input_payload_rsp_inst[15 : 0])});
  assign IBusSimplePlugin_decompressor_isRvc = (IBusSimplePlugin_decompressor_raw[1 : 0] != (2'b11));
  assign _zz_60_ = IBusSimplePlugin_decompressor_raw[15 : 0];
  always @ (*) begin
    IBusSimplePlugin_decompressor_decompressed = 32'h0;
    case(_zz_188_)
      5'b00000 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{{{{{(2'b00),_zz_60_[10 : 7]},_zz_60_[12 : 11]},_zz_60_[5]},_zz_60_[6]},(2'b00)},5'h02},(3'b000)},_zz_62_},7'h13};
      end
      5'b00010 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{_zz_63_,_zz_61_},(3'b010)},_zz_62_},7'h03};
      end
      5'b00110 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{_zz_63_[11 : 5],_zz_62_},_zz_61_},(3'b010)},_zz_63_[4 : 0]},7'h23};
      end
      5'b01000 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{_zz_65_,_zz_60_[11 : 7]},(3'b000)},_zz_60_[11 : 7]},7'h13};
      end
      5'b01001 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{_zz_68_[20],_zz_68_[10 : 1]},_zz_68_[11]},_zz_68_[19 : 12]},_zz_80_},7'h6f};
      end
      5'b01010 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{_zz_65_,5'h0},(3'b000)},_zz_60_[11 : 7]},7'h13};
      end
      5'b01011 : begin
        IBusSimplePlugin_decompressor_decompressed = ((_zz_60_[11 : 7] == 5'h02) ? {{{{{{{{{_zz_72_,_zz_60_[4 : 3]},_zz_60_[5]},_zz_60_[2]},_zz_60_[6]},(4'b0000)},_zz_60_[11 : 7]},(3'b000)},_zz_60_[11 : 7]},7'h13} : {{_zz_219_[31 : 12],_zz_60_[11 : 7]},7'h37});
      end
      5'b01100 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{((_zz_60_[11 : 10] == (2'b10)) ? _zz_86_ : {{(1'b0),(_zz_283_ || _zz_284_)},5'h0}),(((! _zz_60_[11]) || _zz_82_) ? _zz_60_[6 : 2] : _zz_62_)},_zz_61_},_zz_84_},_zz_61_},(_zz_82_ ? 7'h13 : 7'h33)};
      end
      5'b01101 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{_zz_75_[20],_zz_75_[10 : 1]},_zz_75_[11]},_zz_75_[19 : 12]},_zz_79_},7'h6f};
      end
      5'b01110 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{{{_zz_78_[12],_zz_78_[10 : 5]},_zz_79_},_zz_61_},(3'b000)},_zz_78_[4 : 1]},_zz_78_[11]},7'h63};
      end
      5'b01111 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{{{_zz_78_[12],_zz_78_[10 : 5]},_zz_79_},_zz_61_},(3'b001)},_zz_78_[4 : 1]},_zz_78_[11]},7'h63};
      end
      5'b10000 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{7'h0,_zz_60_[6 : 2]},_zz_60_[11 : 7]},(3'b001)},_zz_60_[11 : 7]},7'h13};
      end
      5'b10010 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{{{{(4'b0000),_zz_60_[3 : 2]},_zz_60_[12]},_zz_60_[6 : 4]},(2'b00)},_zz_81_},(3'b010)},_zz_60_[11 : 7]},7'h03};
      end
      5'b10100 : begin
        IBusSimplePlugin_decompressor_decompressed = ((_zz_60_[12 : 2] == 11'h400) ? 32'h00100073 : ((_zz_60_[6 : 2] == 5'h0) ? {{{{12'h0,_zz_60_[11 : 7]},(3'b000)},(_zz_60_[12] ? _zz_80_ : _zz_79_)},7'h67} : {{{{{_zz_285_,_zz_286_},(_zz_287_ ? _zz_288_ : _zz_79_)},(3'b000)},_zz_60_[11 : 7]},7'h33}));
      end
      5'b10110 : begin
        IBusSimplePlugin_decompressor_decompressed = {{{{{_zz_220_[11 : 5],_zz_60_[6 : 2]},_zz_81_},(3'b010)},_zz_221_[4 : 0]},7'h23};
      end
      default : begin
      end
    endcase
  end

  assign _zz_61_ = {(2'b01),_zz_60_[9 : 7]};
  assign _zz_62_ = {(2'b01),_zz_60_[4 : 2]};
  assign _zz_63_ = {{{{5'h0,_zz_60_[5]},_zz_60_[12 : 10]},_zz_60_[6]},(2'b00)};
  assign _zz_64_ = _zz_60_[12];
  always @ (*) begin
    _zz_65_[11] = _zz_64_;
    _zz_65_[10] = _zz_64_;
    _zz_65_[9] = _zz_64_;
    _zz_65_[8] = _zz_64_;
    _zz_65_[7] = _zz_64_;
    _zz_65_[6] = _zz_64_;
    _zz_65_[5] = _zz_64_;
    _zz_65_[4 : 0] = _zz_60_[6 : 2];
  end

  assign _zz_66_ = _zz_60_[12];
  always @ (*) begin
    _zz_67_[9] = _zz_66_;
    _zz_67_[8] = _zz_66_;
    _zz_67_[7] = _zz_66_;
    _zz_67_[6] = _zz_66_;
    _zz_67_[5] = _zz_66_;
    _zz_67_[4] = _zz_66_;
    _zz_67_[3] = _zz_66_;
    _zz_67_[2] = _zz_66_;
    _zz_67_[1] = _zz_66_;
    _zz_67_[0] = _zz_66_;
  end

  assign _zz_68_ = {{{{{{{{_zz_67_,_zz_60_[8]},_zz_60_[10 : 9]},_zz_60_[6]},_zz_60_[7]},_zz_60_[2]},_zz_60_[11]},_zz_60_[5 : 3]},(1'b0)};
  assign _zz_69_ = _zz_60_[12];
  always @ (*) begin
    _zz_70_[14] = _zz_69_;
    _zz_70_[13] = _zz_69_;
    _zz_70_[12] = _zz_69_;
    _zz_70_[11] = _zz_69_;
    _zz_70_[10] = _zz_69_;
    _zz_70_[9] = _zz_69_;
    _zz_70_[8] = _zz_69_;
    _zz_70_[7] = _zz_69_;
    _zz_70_[6] = _zz_69_;
    _zz_70_[5] = _zz_69_;
    _zz_70_[4] = _zz_69_;
    _zz_70_[3] = _zz_69_;
    _zz_70_[2] = _zz_69_;
    _zz_70_[1] = _zz_69_;
    _zz_70_[0] = _zz_69_;
  end

  assign _zz_71_ = _zz_60_[12];
  always @ (*) begin
    _zz_72_[2] = _zz_71_;
    _zz_72_[1] = _zz_71_;
    _zz_72_[0] = _zz_71_;
  end

  assign _zz_73_ = _zz_60_[12];
  always @ (*) begin
    _zz_74_[9] = _zz_73_;
    _zz_74_[8] = _zz_73_;
    _zz_74_[7] = _zz_73_;
    _zz_74_[6] = _zz_73_;
    _zz_74_[5] = _zz_73_;
    _zz_74_[4] = _zz_73_;
    _zz_74_[3] = _zz_73_;
    _zz_74_[2] = _zz_73_;
    _zz_74_[1] = _zz_73_;
    _zz_74_[0] = _zz_73_;
  end

  assign _zz_75_ = {{{{{{{{_zz_74_,_zz_60_[8]},_zz_60_[10 : 9]},_zz_60_[6]},_zz_60_[7]},_zz_60_[2]},_zz_60_[11]},_zz_60_[5 : 3]},(1'b0)};
  assign _zz_76_ = _zz_60_[12];
  always @ (*) begin
    _zz_77_[4] = _zz_76_;
    _zz_77_[3] = _zz_76_;
    _zz_77_[2] = _zz_76_;
    _zz_77_[1] = _zz_76_;
    _zz_77_[0] = _zz_76_;
  end

  assign _zz_78_ = {{{{{_zz_77_,_zz_60_[6 : 5]},_zz_60_[2]},_zz_60_[11 : 10]},_zz_60_[4 : 3]},(1'b0)};
  assign _zz_79_ = 5'h0;
  assign _zz_80_ = 5'h01;
  assign _zz_81_ = 5'h02;
  assign _zz_82_ = (_zz_60_[11 : 10] != (2'b11));
  always @ (*) begin
    case(_zz_189_)
      2'b00 : begin
        _zz_83_ = (3'b000);
      end
      2'b01 : begin
        _zz_83_ = (3'b100);
      end
      2'b10 : begin
        _zz_83_ = (3'b110);
      end
      default : begin
        _zz_83_ = (3'b111);
      end
    endcase
  end

  always @ (*) begin
    case(_zz_190_)
      2'b00 : begin
        _zz_84_ = (3'b101);
      end
      2'b01 : begin
        _zz_84_ = (3'b101);
      end
      2'b10 : begin
        _zz_84_ = (3'b111);
      end
      default : begin
        _zz_84_ = _zz_83_;
      end
    endcase
  end

  assign _zz_85_ = _zz_60_[12];
  always @ (*) begin
    _zz_86_[6] = _zz_85_;
    _zz_86_[5] = _zz_85_;
    _zz_86_[4] = _zz_85_;
    _zz_86_[3] = _zz_85_;
    _zz_86_[2] = _zz_85_;
    _zz_86_[1] = _zz_85_;
    _zz_86_[0] = _zz_85_;
  end

  assign IBusSimplePlugin_decompressor_output_valid = (IBusSimplePlugin_decompressor_input_valid && (! ((IBusSimplePlugin_decompressor_throw2Bytes && (! IBusSimplePlugin_decompressor_bufferValid)) && (! IBusSimplePlugin_decompressor_isInputHighRvc))));
  assign IBusSimplePlugin_decompressor_output_payload_pc = IBusSimplePlugin_decompressor_input_payload_pc;
  assign IBusSimplePlugin_decompressor_output_payload_isRvc = IBusSimplePlugin_decompressor_isRvc;
  assign IBusSimplePlugin_decompressor_output_payload_rsp_inst = (IBusSimplePlugin_decompressor_isRvc ? IBusSimplePlugin_decompressor_decompressed : IBusSimplePlugin_decompressor_raw);
  assign IBusSimplePlugin_decompressor_input_ready = (IBusSimplePlugin_decompressor_output_ready && (((! IBusSimplePlugin_iBusRsp_stages_2_input_valid) || IBusSimplePlugin_decompressor_flushNext) || ((! (IBusSimplePlugin_decompressor_bufferValid && IBusSimplePlugin_decompressor_isInputHighRvc)) && (! (((! IBusSimplePlugin_decompressor_unaligned) && IBusSimplePlugin_decompressor_isInputLowRvc) && IBusSimplePlugin_decompressor_isInputHighRvc)))));
  assign IBusSimplePlugin_decompressor_bufferFill = (((((! IBusSimplePlugin_decompressor_unaligned) && IBusSimplePlugin_decompressor_isInputLowRvc) && (! IBusSimplePlugin_decompressor_isInputHighRvc)) || (IBusSimplePlugin_decompressor_bufferValid && (! IBusSimplePlugin_decompressor_isInputHighRvc))) || ((IBusSimplePlugin_decompressor_throw2Bytes && (! IBusSimplePlugin_decompressor_isRvc)) && (! IBusSimplePlugin_decompressor_isInputHighRvc)));
  assign IBusSimplePlugin_decompressor_output_ready = ((1'b0 && (! IBusSimplePlugin_injector_decodeInput_valid)) || IBusSimplePlugin_injector_decodeInput_ready);
  assign IBusSimplePlugin_injector_decodeInput_valid = _zz_87_;
  assign IBusSimplePlugin_injector_decodeInput_payload_pc = _zz_88_;
  assign IBusSimplePlugin_injector_decodeInput_payload_rsp_error = _zz_89_;
  assign IBusSimplePlugin_injector_decodeInput_payload_rsp_inst = _zz_90_;
  assign IBusSimplePlugin_injector_decodeInput_payload_isRvc = _zz_91_;
  assign IBusSimplePlugin_pcValids_0 = IBusSimplePlugin_injector_nextPcCalc_valids_0;
  assign IBusSimplePlugin_pcValids_1 = IBusSimplePlugin_injector_nextPcCalc_valids_1;
  assign IBusSimplePlugin_pcValids_2 = IBusSimplePlugin_injector_nextPcCalc_valids_2;
  assign IBusSimplePlugin_pcValids_3 = IBusSimplePlugin_injector_nextPcCalc_valids_3;
  assign IBusSimplePlugin_injector_decodeInput_ready = (! decode_arbitration_isStuck);
  assign decode_arbitration_isValid = IBusSimplePlugin_injector_decodeInput_valid;
  assign iBus_cmd_valid = IBusSimplePlugin_cmd_valid;
  assign IBusSimplePlugin_cmd_ready = iBus_cmd_ready;
  assign iBus_cmd_payload_pc = IBusSimplePlugin_cmd_payload_pc;
  assign IBusSimplePlugin_pending_next = (_zz_222_ - _zz_226_);
  assign IBusSimplePlugin_cmdFork_canEmit = (IBusSimplePlugin_iBusRsp_stages_1_output_ready && (IBusSimplePlugin_pending_value != (3'b111)));
  assign IBusSimplePlugin_cmd_valid = (IBusSimplePlugin_iBusRsp_stages_1_input_valid && IBusSimplePlugin_cmdFork_canEmit);
  assign IBusSimplePlugin_pending_inc = (IBusSimplePlugin_cmd_valid && IBusSimplePlugin_cmd_ready);
  assign IBusSimplePlugin_cmd_payload_pc = {IBusSimplePlugin_iBusRsp_stages_1_input_payload[31 : 2],(2'b00)};
  assign IBusSimplePlugin_rspJoin_rspBuffer_flush = ((IBusSimplePlugin_rspJoin_rspBuffer_discardCounter != (3'b000)) || IBusSimplePlugin_iBusRsp_flush);
  assign IBusSimplePlugin_rspJoin_rspBuffer_output_valid = (IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_valid && (IBusSimplePlugin_rspJoin_rspBuffer_discardCounter == (3'b000)));
  assign IBusSimplePlugin_rspJoin_rspBuffer_output_payload_error = IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_error;
  assign IBusSimplePlugin_rspJoin_rspBuffer_output_payload_inst = IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_payload_inst;
  assign _zz_159_ = (IBusSimplePlugin_rspJoin_rspBuffer_output_ready || IBusSimplePlugin_rspJoin_rspBuffer_flush);
  assign IBusSimplePlugin_pending_dec = (IBusSimplePlugin_rspJoin_rspBuffer_c_io_pop_valid && _zz_159_);
  assign IBusSimplePlugin_rspJoin_fetchRsp_pc = IBusSimplePlugin_iBusRsp_stages_2_output_payload;
  always @ (*) begin
    IBusSimplePlugin_rspJoin_fetchRsp_rsp_error = IBusSimplePlugin_rspJoin_rspBuffer_output_payload_error;
    if((! IBusSimplePlugin_rspJoin_rspBuffer_output_valid))begin
      IBusSimplePlugin_rspJoin_fetchRsp_rsp_error = 1'b0;
    end
  end

  assign IBusSimplePlugin_rspJoin_fetchRsp_rsp_inst = IBusSimplePlugin_rspJoin_rspBuffer_output_payload_inst;
  assign IBusSimplePlugin_rspJoin_exceptionDetected = 1'b0;
  assign IBusSimplePlugin_rspJoin_join_valid = (IBusSimplePlugin_iBusRsp_stages_2_output_valid && IBusSimplePlugin_rspJoin_rspBuffer_output_valid);
  assign IBusSimplePlugin_rspJoin_join_payload_pc = IBusSimplePlugin_rspJoin_fetchRsp_pc;
  assign IBusSimplePlugin_rspJoin_join_payload_rsp_error = IBusSimplePlugin_rspJoin_fetchRsp_rsp_error;
  assign IBusSimplePlugin_rspJoin_join_payload_rsp_inst = IBusSimplePlugin_rspJoin_fetchRsp_rsp_inst;
  assign IBusSimplePlugin_rspJoin_join_payload_isRvc = IBusSimplePlugin_rspJoin_fetchRsp_isRvc;
  assign IBusSimplePlugin_iBusRsp_stages_2_output_ready = (IBusSimplePlugin_iBusRsp_stages_2_output_valid ? (IBusSimplePlugin_rspJoin_join_valid && IBusSimplePlugin_rspJoin_join_ready) : IBusSimplePlugin_rspJoin_join_ready);
  assign IBusSimplePlugin_rspJoin_rspBuffer_output_ready = (IBusSimplePlugin_rspJoin_join_valid && IBusSimplePlugin_rspJoin_join_ready);
  assign _zz_92_ = (! IBusSimplePlugin_rspJoin_exceptionDetected);
  assign IBusSimplePlugin_rspJoin_join_ready = (IBusSimplePlugin_iBusRsp_output_ready && _zz_92_);
  assign IBusSimplePlugin_iBusRsp_output_valid = (IBusSimplePlugin_rspJoin_join_valid && _zz_92_);
  assign IBusSimplePlugin_iBusRsp_output_payload_pc = IBusSimplePlugin_rspJoin_join_payload_pc;
  assign IBusSimplePlugin_iBusRsp_output_payload_rsp_error = IBusSimplePlugin_rspJoin_join_payload_rsp_error;
  assign IBusSimplePlugin_iBusRsp_output_payload_rsp_inst = IBusSimplePlugin_rspJoin_join_payload_rsp_inst;
  assign IBusSimplePlugin_iBusRsp_output_payload_isRvc = IBusSimplePlugin_rspJoin_join_payload_isRvc;
  assign _zz_93_ = 1'b0;
  always @ (*) begin
    execute_DBusSimplePlugin_skipCmd = 1'b0;
    if(execute_ALIGNEMENT_FAULT)begin
      execute_DBusSimplePlugin_skipCmd = 1'b1;
    end
  end

  assign dBus_cmd_valid = (((((execute_arbitration_isValid && execute_MEMORY_ENABLE) && (! execute_arbitration_isStuckByOthers)) && (! execute_arbitration_isFlushed)) && (! execute_DBusSimplePlugin_skipCmd)) && (! _zz_93_));
  assign dBus_cmd_payload_wr = execute_MEMORY_STORE;
  assign dBus_cmd_payload_size = execute_INSTRUCTION[13 : 12];
  always @ (*) begin
    case(dBus_cmd_payload_size)
      2'b00 : begin
        _zz_94_ = {{{execute_RS2[7 : 0],execute_RS2[7 : 0]},execute_RS2[7 : 0]},execute_RS2[7 : 0]};
      end
      2'b01 : begin
        _zz_94_ = {execute_RS2[15 : 0],execute_RS2[15 : 0]};
      end
      default : begin
        _zz_94_ = execute_RS2[31 : 0];
      end
    endcase
  end

  assign dBus_cmd_payload_data = _zz_94_;
  always @ (*) begin
    case(dBus_cmd_payload_size)
      2'b00 : begin
        _zz_95_ = (4'b0001);
      end
      2'b01 : begin
        _zz_95_ = (4'b0011);
      end
      default : begin
        _zz_95_ = (4'b1111);
      end
    endcase
  end

  assign execute_DBusSimplePlugin_formalMask = (_zz_95_ <<< dBus_cmd_payload_address[1 : 0]);
  assign dBus_cmd_payload_address = execute_SRC_ADD;
  always @ (*) begin
    memory_DBusSimplePlugin_rspShifted = memory_MEMORY_READ_DATA;
    case(memory_MEMORY_ADDRESS_LOW)
      2'b01 : begin
        memory_DBusSimplePlugin_rspShifted[7 : 0] = memory_MEMORY_READ_DATA[15 : 8];
      end
      2'b10 : begin
        memory_DBusSimplePlugin_rspShifted[15 : 0] = memory_MEMORY_READ_DATA[31 : 16];
      end
      2'b11 : begin
        memory_DBusSimplePlugin_rspShifted[7 : 0] = memory_MEMORY_READ_DATA[31 : 24];
      end
      default : begin
      end
    endcase
  end

  assign _zz_96_ = (memory_DBusSimplePlugin_rspShifted[7] && (! memory_INSTRUCTION[14]));
  always @ (*) begin
    _zz_97_[31] = _zz_96_;
    _zz_97_[30] = _zz_96_;
    _zz_97_[29] = _zz_96_;
    _zz_97_[28] = _zz_96_;
    _zz_97_[27] = _zz_96_;
    _zz_97_[26] = _zz_96_;
    _zz_97_[25] = _zz_96_;
    _zz_97_[24] = _zz_96_;
    _zz_97_[23] = _zz_96_;
    _zz_97_[22] = _zz_96_;
    _zz_97_[21] = _zz_96_;
    _zz_97_[20] = _zz_96_;
    _zz_97_[19] = _zz_96_;
    _zz_97_[18] = _zz_96_;
    _zz_97_[17] = _zz_96_;
    _zz_97_[16] = _zz_96_;
    _zz_97_[15] = _zz_96_;
    _zz_97_[14] = _zz_96_;
    _zz_97_[13] = _zz_96_;
    _zz_97_[12] = _zz_96_;
    _zz_97_[11] = _zz_96_;
    _zz_97_[10] = _zz_96_;
    _zz_97_[9] = _zz_96_;
    _zz_97_[8] = _zz_96_;
    _zz_97_[7 : 0] = memory_DBusSimplePlugin_rspShifted[7 : 0];
  end

  assign _zz_98_ = (memory_DBusSimplePlugin_rspShifted[15] && (! memory_INSTRUCTION[14]));
  always @ (*) begin
    _zz_99_[31] = _zz_98_;
    _zz_99_[30] = _zz_98_;
    _zz_99_[29] = _zz_98_;
    _zz_99_[28] = _zz_98_;
    _zz_99_[27] = _zz_98_;
    _zz_99_[26] = _zz_98_;
    _zz_99_[25] = _zz_98_;
    _zz_99_[24] = _zz_98_;
    _zz_99_[23] = _zz_98_;
    _zz_99_[22] = _zz_98_;
    _zz_99_[21] = _zz_98_;
    _zz_99_[20] = _zz_98_;
    _zz_99_[19] = _zz_98_;
    _zz_99_[18] = _zz_98_;
    _zz_99_[17] = _zz_98_;
    _zz_99_[16] = _zz_98_;
    _zz_99_[15 : 0] = memory_DBusSimplePlugin_rspShifted[15 : 0];
  end

  always @ (*) begin
    case(_zz_191_)
      2'b00 : begin
        memory_DBusSimplePlugin_rspFormated = _zz_97_;
      end
      2'b01 : begin
        memory_DBusSimplePlugin_rspFormated = _zz_99_;
      end
      default : begin
        memory_DBusSimplePlugin_rspFormated = memory_DBusSimplePlugin_rspShifted;
      end
    endcase
  end

  always @ (*) begin
    CsrPlugin_privilege = (2'b11);
    if(CsrPlugin_forceMachineWire)begin
      CsrPlugin_privilege = (2'b11);
    end
  end

  assign CsrPlugin_misa_base = (2'b01);
  assign CsrPlugin_misa_extensions = 26'h0000042;
  assign CsrPlugin_mtvec_mode = (2'b00);
  assign CsrPlugin_mtvec_base = 30'h00000001;
  assign _zz_100_ = (CsrPlugin_mip_MTIP && CsrPlugin_mie_MTIE);
  assign _zz_101_ = (CsrPlugin_mip_MSIP && CsrPlugin_mie_MSIE);
  assign _zz_102_ = (CsrPlugin_mip_MEIP && CsrPlugin_mie_MEIE);
  assign CsrPlugin_exception = 1'b0;
  assign CsrPlugin_lastStageWasWfi = 1'b0;
  assign CsrPlugin_pipelineLiberator_active = ((CsrPlugin_interrupt_valid && CsrPlugin_allowInterrupts) && decode_arbitration_isValid);
  always @ (*) begin
    CsrPlugin_pipelineLiberator_done = CsrPlugin_pipelineLiberator_pcValids_2;
    if(CsrPlugin_hadException)begin
      CsrPlugin_pipelineLiberator_done = 1'b0;
    end
  end

  assign CsrPlugin_interruptJump = ((CsrPlugin_interrupt_valid && CsrPlugin_pipelineLiberator_done) && CsrPlugin_allowInterrupts);
  assign CsrPlugin_targetPrivilege = CsrPlugin_interrupt_targetPrivilege;
  assign CsrPlugin_trapCause = CsrPlugin_interrupt_code;
  always @ (*) begin
    CsrPlugin_xtvec_mode = (2'bxx);
    case(CsrPlugin_targetPrivilege)
      2'b11 : begin
        CsrPlugin_xtvec_mode = CsrPlugin_mtvec_mode;
      end
      default : begin
      end
    endcase
  end

  always @ (*) begin
    CsrPlugin_xtvec_base = 30'h0;
    case(CsrPlugin_targetPrivilege)
      2'b11 : begin
        CsrPlugin_xtvec_base = CsrPlugin_mtvec_base;
      end
      default : begin
      end
    endcase
  end

  assign contextSwitching = CsrPlugin_jumpInterface_valid;
  assign execute_CsrPlugin_blockedBySideEffects = ({writeBack_arbitration_isValid,memory_arbitration_isValid} != (2'b00));
  always @ (*) begin
    execute_CsrPlugin_illegalAccess = 1'b1;
    if(execute_CsrPlugin_csr_768)begin
      execute_CsrPlugin_illegalAccess = 1'b0;
    end
    if(execute_CsrPlugin_csr_836)begin
      execute_CsrPlugin_illegalAccess = 1'b0;
    end
    if(execute_CsrPlugin_csr_772)begin
      execute_CsrPlugin_illegalAccess = 1'b0;
    end
    if(execute_CsrPlugin_csr_832)begin
      execute_CsrPlugin_illegalAccess = 1'b0;
    end
    if(execute_CsrPlugin_csr_834)begin
      if(execute_CSR_READ_OPCODE)begin
        execute_CsrPlugin_illegalAccess = 1'b0;
      end
    end
    if((CsrPlugin_privilege < execute_CsrPlugin_csrAddress[9 : 8]))begin
      execute_CsrPlugin_illegalAccess = 1'b1;
    end
    if(((! execute_arbitration_isValid) || (! execute_IS_CSR)))begin
      execute_CsrPlugin_illegalAccess = 1'b0;
    end
  end

  always @ (*) begin
    execute_CsrPlugin_illegalInstruction = 1'b0;
    if((execute_arbitration_isValid && (execute_ENV_CTRL == `EnvCtrlEnum_defaultEncoding_XRET)))begin
      if((CsrPlugin_privilege < execute_INSTRUCTION[29 : 28]))begin
        execute_CsrPlugin_illegalInstruction = 1'b1;
      end
    end
  end

  assign execute_CsrPlugin_writeInstruction = ((execute_arbitration_isValid && execute_IS_CSR) && execute_CSR_WRITE_OPCODE);
  assign execute_CsrPlugin_readInstruction = ((execute_arbitration_isValid && execute_IS_CSR) && execute_CSR_READ_OPCODE);
  assign execute_CsrPlugin_writeEnable = ((execute_CsrPlugin_writeInstruction && (! execute_CsrPlugin_blockedBySideEffects)) && (! execute_arbitration_isStuckByOthers));
  assign execute_CsrPlugin_readEnable = ((execute_CsrPlugin_readInstruction && (! execute_CsrPlugin_blockedBySideEffects)) && (! execute_arbitration_isStuckByOthers));
  assign execute_CsrPlugin_readToWriteData = execute_CsrPlugin_readData;
  always @ (*) begin
    case(_zz_192_)
      1'b0 : begin
        execute_CsrPlugin_writeData = execute_SRC1;
      end
      default : begin
        execute_CsrPlugin_writeData = (execute_INSTRUCTION[12] ? (execute_CsrPlugin_readToWriteData & (~ execute_SRC1)) : (execute_CsrPlugin_readToWriteData | execute_SRC1));
      end
    endcase
  end

  assign execute_CsrPlugin_csrAddress = execute_INSTRUCTION[31 : 20];
  assign _zz_104_ = ((decode_INSTRUCTION & 32'h00006004) == 32'h00002000);
  assign _zz_105_ = ((decode_INSTRUCTION & 32'h00007000) == 32'h00001000);
  assign _zz_106_ = ((decode_INSTRUCTION & 32'h00003000) == 32'h00002000);
  assign _zz_107_ = ((decode_INSTRUCTION & 32'h00005000) == 32'h00004000);
  assign _zz_108_ = ((decode_INSTRUCTION & 32'h00004050) == 32'h00004050);
  assign _zz_109_ = ((decode_INSTRUCTION & 32'h00000048) == 32'h00000048);
  assign _zz_110_ = ((decode_INSTRUCTION & 32'h00000004) == 32'h00000004);
  assign _zz_103_ = {({(_zz_289_ == _zz_290_),{_zz_291_,{_zz_292_,_zz_293_}}} != (4'b0000)),{({_zz_110_,_zz_294_} != (2'b00)),{({_zz_295_,_zz_296_} != (2'b00)),{(_zz_297_ != _zz_298_),{_zz_299_,{_zz_300_,_zz_301_}}}}}};
  assign _zz_111_ = _zz_103_[3 : 2];
  assign _zz_43_ = _zz_111_;
  assign _zz_112_ = _zz_103_[9 : 8];
  assign _zz_42_ = _zz_112_;
  assign _zz_113_ = _zz_103_[10 : 10];
  assign _zz_41_ = _zz_113_;
  assign _zz_114_ = _zz_103_[12 : 11];
  assign _zz_40_ = _zz_114_;
  assign _zz_115_ = _zz_103_[15 : 14];
  assign _zz_39_ = _zz_115_;
  assign _zz_116_ = _zz_103_[23 : 22];
  assign _zz_38_ = _zz_116_;
  assign _zz_117_ = _zz_103_[27 : 26];
  assign _zz_37_ = _zz_117_;
  assign decode_RegFilePlugin_regFileReadAddress1 = decode_INSTRUCTION_ANTICIPATED[18 : 15];
  assign decode_RegFilePlugin_regFileReadAddress2 = decode_INSTRUCTION_ANTICIPATED[23 : 20];
  assign decode_RegFilePlugin_rs1Data = _zz_161_;
  assign decode_RegFilePlugin_rs2Data = _zz_162_;
  always @ (*) begin
    lastStageRegFileWrite_valid = (_zz_35_ && writeBack_arbitration_isFiring);
    if(_zz_118_)begin
      lastStageRegFileWrite_valid = 1'b1;
    end
  end

  assign lastStageRegFileWrite_payload_address = _zz_34_[10 : 7];
  assign lastStageRegFileWrite_payload_data = _zz_33_;
  always @ (*) begin
    case(execute_ALU_BITWISE_CTRL)
      `AluBitwiseCtrlEnum_defaultEncoding_AND_1 : begin
        execute_IntAluPlugin_bitwise = (execute_SRC1 & execute_SRC2);
      end
      `AluBitwiseCtrlEnum_defaultEncoding_OR_1 : begin
        execute_IntAluPlugin_bitwise = (execute_SRC1 | execute_SRC2);
      end
      default : begin
        execute_IntAluPlugin_bitwise = (execute_SRC1 ^ execute_SRC2);
      end
    endcase
  end

  always @ (*) begin
    case(execute_ALU_CTRL)
      `AluCtrlEnum_defaultEncoding_BITWISE : begin
        _zz_119_ = execute_IntAluPlugin_bitwise;
      end
      `AluCtrlEnum_defaultEncoding_SLT_SLTU : begin
        _zz_119_ = {31'd0, _zz_229_};
      end
      default : begin
        _zz_119_ = execute_SRC_ADD_SUB;
      end
    endcase
  end

  always @ (*) begin
    case(execute_SRC1_CTRL)
      `Src1CtrlEnum_defaultEncoding_RS : begin
        _zz_120_ = execute_RS1;
      end
      `Src1CtrlEnum_defaultEncoding_PC_INCREMENT : begin
        _zz_120_ = {29'd0, _zz_230_};
      end
      `Src1CtrlEnum_defaultEncoding_IMU : begin
        _zz_120_ = {execute_INSTRUCTION[31 : 12],12'h0};
      end
      default : begin
        _zz_120_ = {27'd0, _zz_231_};
      end
    endcase
  end

  assign _zz_121_ = _zz_232_[11];
  always @ (*) begin
    _zz_122_[19] = _zz_121_;
    _zz_122_[18] = _zz_121_;
    _zz_122_[17] = _zz_121_;
    _zz_122_[16] = _zz_121_;
    _zz_122_[15] = _zz_121_;
    _zz_122_[14] = _zz_121_;
    _zz_122_[13] = _zz_121_;
    _zz_122_[12] = _zz_121_;
    _zz_122_[11] = _zz_121_;
    _zz_122_[10] = _zz_121_;
    _zz_122_[9] = _zz_121_;
    _zz_122_[8] = _zz_121_;
    _zz_122_[7] = _zz_121_;
    _zz_122_[6] = _zz_121_;
    _zz_122_[5] = _zz_121_;
    _zz_122_[4] = _zz_121_;
    _zz_122_[3] = _zz_121_;
    _zz_122_[2] = _zz_121_;
    _zz_122_[1] = _zz_121_;
    _zz_122_[0] = _zz_121_;
  end

  assign _zz_123_ = _zz_233_[11];
  always @ (*) begin
    _zz_124_[19] = _zz_123_;
    _zz_124_[18] = _zz_123_;
    _zz_124_[17] = _zz_123_;
    _zz_124_[16] = _zz_123_;
    _zz_124_[15] = _zz_123_;
    _zz_124_[14] = _zz_123_;
    _zz_124_[13] = _zz_123_;
    _zz_124_[12] = _zz_123_;
    _zz_124_[11] = _zz_123_;
    _zz_124_[10] = _zz_123_;
    _zz_124_[9] = _zz_123_;
    _zz_124_[8] = _zz_123_;
    _zz_124_[7] = _zz_123_;
    _zz_124_[6] = _zz_123_;
    _zz_124_[5] = _zz_123_;
    _zz_124_[4] = _zz_123_;
    _zz_124_[3] = _zz_123_;
    _zz_124_[2] = _zz_123_;
    _zz_124_[1] = _zz_123_;
    _zz_124_[0] = _zz_123_;
  end

  always @ (*) begin
    case(execute_SRC2_CTRL)
      `Src2CtrlEnum_defaultEncoding_RS : begin
        _zz_125_ = execute_RS2;
      end
      `Src2CtrlEnum_defaultEncoding_IMI : begin
        _zz_125_ = {_zz_122_,execute_INSTRUCTION[31 : 20]};
      end
      `Src2CtrlEnum_defaultEncoding_IMS : begin
        _zz_125_ = {_zz_124_,{execute_INSTRUCTION[31 : 25],execute_INSTRUCTION[11 : 7]}};
      end
      default : begin
        _zz_125_ = _zz_28_;
      end
    endcase
  end

  always @ (*) begin
    execute_SrcPlugin_addSub = _zz_234_;
    if(execute_SRC2_FORCE_ZERO)begin
      execute_SrcPlugin_addSub = execute_SRC1;
    end
  end

  assign execute_SrcPlugin_less = ((execute_SRC1[31] == execute_SRC2[31]) ? execute_SrcPlugin_addSub[31] : (execute_SRC_LESS_UNSIGNED ? execute_SRC2[31] : execute_SRC1[31]));
  assign execute_FullBarrelShifterPlugin_amplitude = execute_SRC2[4 : 0];
  always @ (*) begin
    _zz_126_[0] = execute_SRC1[31];
    _zz_126_[1] = execute_SRC1[30];
    _zz_126_[2] = execute_SRC1[29];
    _zz_126_[3] = execute_SRC1[28];
    _zz_126_[4] = execute_SRC1[27];
    _zz_126_[5] = execute_SRC1[26];
    _zz_126_[6] = execute_SRC1[25];
    _zz_126_[7] = execute_SRC1[24];
    _zz_126_[8] = execute_SRC1[23];
    _zz_126_[9] = execute_SRC1[22];
    _zz_126_[10] = execute_SRC1[21];
    _zz_126_[11] = execute_SRC1[20];
    _zz_126_[12] = execute_SRC1[19];
    _zz_126_[13] = execute_SRC1[18];
    _zz_126_[14] = execute_SRC1[17];
    _zz_126_[15] = execute_SRC1[16];
    _zz_126_[16] = execute_SRC1[15];
    _zz_126_[17] = execute_SRC1[14];
    _zz_126_[18] = execute_SRC1[13];
    _zz_126_[19] = execute_SRC1[12];
    _zz_126_[20] = execute_SRC1[11];
    _zz_126_[21] = execute_SRC1[10];
    _zz_126_[22] = execute_SRC1[9];
    _zz_126_[23] = execute_SRC1[8];
    _zz_126_[24] = execute_SRC1[7];
    _zz_126_[25] = execute_SRC1[6];
    _zz_126_[26] = execute_SRC1[5];
    _zz_126_[27] = execute_SRC1[4];
    _zz_126_[28] = execute_SRC1[3];
    _zz_126_[29] = execute_SRC1[2];
    _zz_126_[30] = execute_SRC1[1];
    _zz_126_[31] = execute_SRC1[0];
  end

  assign execute_FullBarrelShifterPlugin_reversed = ((execute_SHIFT_CTRL == `ShiftCtrlEnum_defaultEncoding_SLL_1) ? _zz_126_ : execute_SRC1);
  always @ (*) begin
    _zz_127_[0] = execute_SHIFT_RIGHT[31];
    _zz_127_[1] = execute_SHIFT_RIGHT[30];
    _zz_127_[2] = execute_SHIFT_RIGHT[29];
    _zz_127_[3] = execute_SHIFT_RIGHT[28];
    _zz_127_[4] = execute_SHIFT_RIGHT[27];
    _zz_127_[5] = execute_SHIFT_RIGHT[26];
    _zz_127_[6] = execute_SHIFT_RIGHT[25];
    _zz_127_[7] = execute_SHIFT_RIGHT[24];
    _zz_127_[8] = execute_SHIFT_RIGHT[23];
    _zz_127_[9] = execute_SHIFT_RIGHT[22];
    _zz_127_[10] = execute_SHIFT_RIGHT[21];
    _zz_127_[11] = execute_SHIFT_RIGHT[20];
    _zz_127_[12] = execute_SHIFT_RIGHT[19];
    _zz_127_[13] = execute_SHIFT_RIGHT[18];
    _zz_127_[14] = execute_SHIFT_RIGHT[17];
    _zz_127_[15] = execute_SHIFT_RIGHT[16];
    _zz_127_[16] = execute_SHIFT_RIGHT[15];
    _zz_127_[17] = execute_SHIFT_RIGHT[14];
    _zz_127_[18] = execute_SHIFT_RIGHT[13];
    _zz_127_[19] = execute_SHIFT_RIGHT[12];
    _zz_127_[20] = execute_SHIFT_RIGHT[11];
    _zz_127_[21] = execute_SHIFT_RIGHT[10];
    _zz_127_[22] = execute_SHIFT_RIGHT[9];
    _zz_127_[23] = execute_SHIFT_RIGHT[8];
    _zz_127_[24] = execute_SHIFT_RIGHT[7];
    _zz_127_[25] = execute_SHIFT_RIGHT[6];
    _zz_127_[26] = execute_SHIFT_RIGHT[5];
    _zz_127_[27] = execute_SHIFT_RIGHT[4];
    _zz_127_[28] = execute_SHIFT_RIGHT[3];
    _zz_127_[29] = execute_SHIFT_RIGHT[2];
    _zz_127_[30] = execute_SHIFT_RIGHT[1];
    _zz_127_[31] = execute_SHIFT_RIGHT[0];
  end

  always @ (*) begin
    _zz_128_ = 1'b0;
    if(_zz_175_)begin
      if(_zz_176_)begin
        if(_zz_133_)begin
          _zz_128_ = 1'b1;
        end
      end
    end
    if(_zz_177_)begin
      if(_zz_178_)begin
        if(_zz_135_)begin
          _zz_128_ = 1'b1;
        end
      end
    end
    if(_zz_179_)begin
      if(_zz_180_)begin
        if(_zz_137_)begin
          _zz_128_ = 1'b1;
        end
      end
    end
    if((! decode_RS1_USE))begin
      _zz_128_ = 1'b0;
    end
  end

  always @ (*) begin
    _zz_129_ = 1'b0;
    if(_zz_175_)begin
      if(_zz_176_)begin
        if(_zz_134_)begin
          _zz_129_ = 1'b1;
        end
      end
    end
    if(_zz_177_)begin
      if(_zz_178_)begin
        if(_zz_136_)begin
          _zz_129_ = 1'b1;
        end
      end
    end
    if(_zz_179_)begin
      if(_zz_180_)begin
        if(_zz_138_)begin
          _zz_129_ = 1'b1;
        end
      end
    end
    if((! decode_RS2_USE))begin
      _zz_129_ = 1'b0;
    end
  end

  assign _zz_133_ = (writeBack_INSTRUCTION[11 : 7] == decode_INSTRUCTION[19 : 15]);
  assign _zz_134_ = (writeBack_INSTRUCTION[11 : 7] == decode_INSTRUCTION[24 : 20]);
  assign _zz_135_ = (memory_INSTRUCTION[11 : 7] == decode_INSTRUCTION[19 : 15]);
  assign _zz_136_ = (memory_INSTRUCTION[11 : 7] == decode_INSTRUCTION[24 : 20]);
  assign _zz_137_ = (execute_INSTRUCTION[11 : 7] == decode_INSTRUCTION[19 : 15]);
  assign _zz_138_ = (execute_INSTRUCTION[11 : 7] == decode_INSTRUCTION[24 : 20]);
  assign memory_MulDivIterativePlugin_frontendOk = 1'b1;
  always @ (*) begin
    memory_MulDivIterativePlugin_mul_counter_willIncrement = 1'b0;
    if(_zz_168_)begin
      if(_zz_170_)begin
        memory_MulDivIterativePlugin_mul_counter_willIncrement = 1'b1;
      end
    end
  end

  always @ (*) begin
    memory_MulDivIterativePlugin_mul_counter_willClear = 1'b0;
    if((! memory_arbitration_isStuck))begin
      memory_MulDivIterativePlugin_mul_counter_willClear = 1'b1;
    end
  end

  assign memory_MulDivIterativePlugin_mul_counter_willOverflowIfInc = (memory_MulDivIterativePlugin_mul_counter_value == 5'h10);
  assign memory_MulDivIterativePlugin_mul_counter_willOverflow = (memory_MulDivIterativePlugin_mul_counter_willOverflowIfInc && memory_MulDivIterativePlugin_mul_counter_willIncrement);
  always @ (*) begin
    if(memory_MulDivIterativePlugin_mul_counter_willOverflow)begin
      memory_MulDivIterativePlugin_mul_counter_valueNext = 5'h0;
    end else begin
      memory_MulDivIterativePlugin_mul_counter_valueNext = (memory_MulDivIterativePlugin_mul_counter_value + _zz_242_);
    end
    if(memory_MulDivIterativePlugin_mul_counter_willClear)begin
      memory_MulDivIterativePlugin_mul_counter_valueNext = 5'h0;
    end
  end

  always @ (*) begin
    memory_MulDivIterativePlugin_div_counter_willIncrement = 1'b0;
    if(_zz_169_)begin
      if(_zz_181_)begin
        memory_MulDivIterativePlugin_div_counter_willIncrement = 1'b1;
      end
    end
  end

  always @ (*) begin
    memory_MulDivIterativePlugin_div_counter_willClear = 1'b0;
    if(_zz_182_)begin
      memory_MulDivIterativePlugin_div_counter_willClear = 1'b1;
    end
  end

  assign memory_MulDivIterativePlugin_div_counter_willOverflowIfInc = (memory_MulDivIterativePlugin_div_counter_value == 5'h11);
  assign memory_MulDivIterativePlugin_div_counter_willOverflow = (memory_MulDivIterativePlugin_div_counter_willOverflowIfInc && memory_MulDivIterativePlugin_div_counter_willIncrement);
  always @ (*) begin
    if(memory_MulDivIterativePlugin_div_counter_willOverflow)begin
      memory_MulDivIterativePlugin_div_counter_valueNext = 5'h0;
    end else begin
      memory_MulDivIterativePlugin_div_counter_valueNext = (memory_MulDivIterativePlugin_div_counter_value + _zz_254_);
    end
    if(memory_MulDivIterativePlugin_div_counter_willClear)begin
      memory_MulDivIterativePlugin_div_counter_valueNext = 5'h0;
    end
  end

  assign _zz_139_ = memory_MulDivIterativePlugin_rs1[31 : 0];
  assign memory_MulDivIterativePlugin_div_stage_0_remainderShifted = {memory_MulDivIterativePlugin_accumulator[31 : 0],_zz_139_[31]};
  assign memory_MulDivIterativePlugin_div_stage_0_remainderMinusDenominator = (memory_MulDivIterativePlugin_div_stage_0_remainderShifted - _zz_255_);
  assign memory_MulDivIterativePlugin_div_stage_0_outRemainder = ((! memory_MulDivIterativePlugin_div_stage_0_remainderMinusDenominator[32]) ? _zz_256_ : _zz_257_);
  assign memory_MulDivIterativePlugin_div_stage_0_outNumerator = _zz_258_[31:0];
  assign memory_MulDivIterativePlugin_div_stage_1_remainderShifted = {memory_MulDivIterativePlugin_div_stage_0_outRemainder,memory_MulDivIterativePlugin_div_stage_0_outNumerator[31]};
  assign memory_MulDivIterativePlugin_div_stage_1_remainderMinusDenominator = (memory_MulDivIterativePlugin_div_stage_1_remainderShifted - _zz_259_);
  assign memory_MulDivIterativePlugin_div_stage_1_outRemainder = ((! memory_MulDivIterativePlugin_div_stage_1_remainderMinusDenominator[32]) ? _zz_260_ : _zz_261_);
  assign memory_MulDivIterativePlugin_div_stage_1_outNumerator = _zz_262_[31:0];
  assign _zz_140_ = (memory_INSTRUCTION[13] ? memory_MulDivIterativePlugin_accumulator[31 : 0] : memory_MulDivIterativePlugin_rs1[31 : 0]);
  assign _zz_141_ = (execute_RS2[31] && execute_IS_RS2_SIGNED);
  assign _zz_142_ = ((execute_IS_MUL && _zz_141_) || ((execute_IS_DIV && execute_RS1[31]) && execute_IS_RS1_SIGNED));
  always @ (*) begin
    _zz_143_[32] = (execute_IS_RS1_SIGNED && execute_RS1[31]);
    _zz_143_[31 : 0] = execute_RS1;
  end

  assign execute_BranchPlugin_eq = (execute_SRC1 == execute_SRC2);
  assign _zz_144_ = execute_INSTRUCTION[14 : 12];
  always @ (*) begin
    if((_zz_144_ == (3'b000))) begin
        _zz_145_ = execute_BranchPlugin_eq;
    end else if((_zz_144_ == (3'b001))) begin
        _zz_145_ = (! execute_BranchPlugin_eq);
    end else if((((_zz_144_ & (3'b101)) == (3'b101)))) begin
        _zz_145_ = (! execute_SRC_LESS);
    end else begin
        _zz_145_ = execute_SRC_LESS;
    end
  end

  always @ (*) begin
    case(execute_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_INC : begin
        _zz_146_ = 1'b0;
      end
      `BranchCtrlEnum_defaultEncoding_JAL : begin
        _zz_146_ = 1'b1;
      end
      `BranchCtrlEnum_defaultEncoding_JALR : begin
        _zz_146_ = 1'b1;
      end
      default : begin
        _zz_146_ = _zz_145_;
      end
    endcase
  end

  assign execute_BranchPlugin_branch_src1 = ((execute_BRANCH_CTRL == `BranchCtrlEnum_defaultEncoding_JALR) ? execute_RS1 : execute_PC);
  assign _zz_147_ = _zz_272_[19];
  always @ (*) begin
    _zz_148_[10] = _zz_147_;
    _zz_148_[9] = _zz_147_;
    _zz_148_[8] = _zz_147_;
    _zz_148_[7] = _zz_147_;
    _zz_148_[6] = _zz_147_;
    _zz_148_[5] = _zz_147_;
    _zz_148_[4] = _zz_147_;
    _zz_148_[3] = _zz_147_;
    _zz_148_[2] = _zz_147_;
    _zz_148_[1] = _zz_147_;
    _zz_148_[0] = _zz_147_;
  end

  assign _zz_149_ = _zz_273_[11];
  always @ (*) begin
    _zz_150_[19] = _zz_149_;
    _zz_150_[18] = _zz_149_;
    _zz_150_[17] = _zz_149_;
    _zz_150_[16] = _zz_149_;
    _zz_150_[15] = _zz_149_;
    _zz_150_[14] = _zz_149_;
    _zz_150_[13] = _zz_149_;
    _zz_150_[12] = _zz_149_;
    _zz_150_[11] = _zz_149_;
    _zz_150_[10] = _zz_149_;
    _zz_150_[9] = _zz_149_;
    _zz_150_[8] = _zz_149_;
    _zz_150_[7] = _zz_149_;
    _zz_150_[6] = _zz_149_;
    _zz_150_[5] = _zz_149_;
    _zz_150_[4] = _zz_149_;
    _zz_150_[3] = _zz_149_;
    _zz_150_[2] = _zz_149_;
    _zz_150_[1] = _zz_149_;
    _zz_150_[0] = _zz_149_;
  end

  assign _zz_151_ = _zz_274_[11];
  always @ (*) begin
    _zz_152_[18] = _zz_151_;
    _zz_152_[17] = _zz_151_;
    _zz_152_[16] = _zz_151_;
    _zz_152_[15] = _zz_151_;
    _zz_152_[14] = _zz_151_;
    _zz_152_[13] = _zz_151_;
    _zz_152_[12] = _zz_151_;
    _zz_152_[11] = _zz_151_;
    _zz_152_[10] = _zz_151_;
    _zz_152_[9] = _zz_151_;
    _zz_152_[8] = _zz_151_;
    _zz_152_[7] = _zz_151_;
    _zz_152_[6] = _zz_151_;
    _zz_152_[5] = _zz_151_;
    _zz_152_[4] = _zz_151_;
    _zz_152_[3] = _zz_151_;
    _zz_152_[2] = _zz_151_;
    _zz_152_[1] = _zz_151_;
    _zz_152_[0] = _zz_151_;
  end

  always @ (*) begin
    case(execute_BRANCH_CTRL)
      `BranchCtrlEnum_defaultEncoding_JAL : begin
        _zz_153_ = {{_zz_148_,{{{execute_INSTRUCTION[31],execute_INSTRUCTION[19 : 12]},execute_INSTRUCTION[20]},execute_INSTRUCTION[30 : 21]}},1'b0};
      end
      `BranchCtrlEnum_defaultEncoding_JALR : begin
        _zz_153_ = {_zz_150_,execute_INSTRUCTION[31 : 20]};
      end
      default : begin
        _zz_153_ = {{_zz_152_,{{{execute_INSTRUCTION[31],execute_INSTRUCTION[7]},execute_INSTRUCTION[30 : 25]},execute_INSTRUCTION[11 : 8]}},1'b0};
      end
    endcase
  end

  assign execute_BranchPlugin_branch_src2 = _zz_153_;
  assign execute_BranchPlugin_branchAdder = (execute_BranchPlugin_branch_src1 + execute_BranchPlugin_branch_src2);
  assign BranchPlugin_jumpInterface_valid = ((execute_arbitration_isValid && execute_BRANCH_DO) && (! 1'b0));
  assign BranchPlugin_jumpInterface_payload = execute_BRANCH_CALC;
  assign _zz_25_ = decode_ENV_CTRL;
  assign _zz_22_ = execute_ENV_CTRL;
  assign _zz_20_ = memory_ENV_CTRL;
  assign _zz_23_ = _zz_41_;
  assign _zz_46_ = decode_to_execute_ENV_CTRL;
  assign _zz_45_ = execute_to_memory_ENV_CTRL;
  assign _zz_47_ = memory_to_writeBack_ENV_CTRL;
  assign _zz_18_ = decode_ALU_CTRL;
  assign _zz_16_ = _zz_43_;
  assign _zz_31_ = decode_to_execute_ALU_CTRL;
  assign _zz_15_ = decode_BRANCH_CTRL;
  assign _zz_13_ = _zz_39_;
  assign _zz_26_ = decode_to_execute_BRANCH_CTRL;
  assign _zz_12_ = decode_SRC1_CTRL;
  assign _zz_10_ = _zz_40_;
  assign _zz_30_ = decode_to_execute_SRC1_CTRL;
  assign _zz_9_ = decode_SHIFT_CTRL;
  assign _zz_7_ = _zz_42_;
  assign _zz_27_ = decode_to_execute_SHIFT_CTRL;
  assign _zz_6_ = decode_SRC2_CTRL;
  assign _zz_4_ = _zz_37_;
  assign _zz_29_ = decode_to_execute_SRC2_CTRL;
  assign _zz_3_ = decode_ALU_BITWISE_CTRL;
  assign _zz_1_ = _zz_38_;
  assign _zz_32_ = decode_to_execute_ALU_BITWISE_CTRL;
  assign decode_arbitration_isFlushed = (({writeBack_arbitration_flushNext,{memory_arbitration_flushNext,execute_arbitration_flushNext}} != (3'b000)) || ({writeBack_arbitration_flushIt,{memory_arbitration_flushIt,{execute_arbitration_flushIt,decode_arbitration_flushIt}}} != (4'b0000)));
  assign execute_arbitration_isFlushed = (({writeBack_arbitration_flushNext,memory_arbitration_flushNext} != (2'b00)) || ({writeBack_arbitration_flushIt,{memory_arbitration_flushIt,execute_arbitration_flushIt}} != (3'b000)));
  assign memory_arbitration_isFlushed = ((writeBack_arbitration_flushNext != (1'b0)) || ({writeBack_arbitration_flushIt,memory_arbitration_flushIt} != (2'b00)));
  assign writeBack_arbitration_isFlushed = (1'b0 || (writeBack_arbitration_flushIt != (1'b0)));
  assign decode_arbitration_isStuckByOthers = (decode_arbitration_haltByOther || (((1'b0 || execute_arbitration_isStuck) || memory_arbitration_isStuck) || writeBack_arbitration_isStuck));
  assign decode_arbitration_isStuck = (decode_arbitration_haltItself || decode_arbitration_isStuckByOthers);
  assign decode_arbitration_isMoving = ((! decode_arbitration_isStuck) && (! decode_arbitration_removeIt));
  assign decode_arbitration_isFiring = ((decode_arbitration_isValid && (! decode_arbitration_isStuck)) && (! decode_arbitration_removeIt));
  assign execute_arbitration_isStuckByOthers = (execute_arbitration_haltByOther || ((1'b0 || memory_arbitration_isStuck) || writeBack_arbitration_isStuck));
  assign execute_arbitration_isStuck = (execute_arbitration_haltItself || execute_arbitration_isStuckByOthers);
  assign execute_arbitration_isMoving = ((! execute_arbitration_isStuck) && (! execute_arbitration_removeIt));
  assign execute_arbitration_isFiring = ((execute_arbitration_isValid && (! execute_arbitration_isStuck)) && (! execute_arbitration_removeIt));
  assign memory_arbitration_isStuckByOthers = (memory_arbitration_haltByOther || (1'b0 || writeBack_arbitration_isStuck));
  assign memory_arbitration_isStuck = (memory_arbitration_haltItself || memory_arbitration_isStuckByOthers);
  assign memory_arbitration_isMoving = ((! memory_arbitration_isStuck) && (! memory_arbitration_removeIt));
  assign memory_arbitration_isFiring = ((memory_arbitration_isValid && (! memory_arbitration_isStuck)) && (! memory_arbitration_removeIt));
  assign writeBack_arbitration_isStuckByOthers = (writeBack_arbitration_haltByOther || 1'b0);
  assign writeBack_arbitration_isStuck = (writeBack_arbitration_haltItself || writeBack_arbitration_isStuckByOthers);
  assign writeBack_arbitration_isMoving = ((! writeBack_arbitration_isStuck) && (! writeBack_arbitration_removeIt));
  assign writeBack_arbitration_isFiring = ((writeBack_arbitration_isValid && (! writeBack_arbitration_isStuck)) && (! writeBack_arbitration_removeIt));
  always @ (*) begin
    _zz_154_ = 32'h0;
    if(execute_CsrPlugin_csr_768)begin
      _zz_154_[12 : 11] = CsrPlugin_mstatus_MPP;
      _zz_154_[7 : 7] = CsrPlugin_mstatus_MPIE;
      _zz_154_[3 : 3] = CsrPlugin_mstatus_MIE;
    end
  end

  always @ (*) begin
    _zz_155_ = 32'h0;
    if(execute_CsrPlugin_csr_836)begin
      _zz_155_[11 : 11] = CsrPlugin_mip_MEIP;
      _zz_155_[7 : 7] = CsrPlugin_mip_MTIP;
      _zz_155_[3 : 3] = CsrPlugin_mip_MSIP;
    end
  end

  always @ (*) begin
    _zz_156_ = 32'h0;
    if(execute_CsrPlugin_csr_772)begin
      _zz_156_[11 : 11] = CsrPlugin_mie_MEIE;
      _zz_156_[7 : 7] = CsrPlugin_mie_MTIE;
      _zz_156_[3 : 3] = CsrPlugin_mie_MSIE;
    end
  end

  always @ (*) begin
    _zz_157_ = 32'h0;
    if(execute_CsrPlugin_csr_832)begin
      _zz_157_[31 : 0] = CsrPlugin_mscratch;
    end
  end

  always @ (*) begin
    _zz_158_ = 32'h0;
    if(execute_CsrPlugin_csr_834)begin
      _zz_158_[31 : 31] = CsrPlugin_mcause_interrupt;
      _zz_158_[3 : 0] = CsrPlugin_mcause_exceptionCode;
    end
  end

  assign execute_CsrPlugin_readData = (((_zz_154_ | _zz_155_) | (_zz_156_ | _zz_157_)) | _zz_158_);
  assign _zz_160_ = 1'b0;
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      IBusSimplePlugin_fetchPc_pcReg <= 32'h0;
      IBusSimplePlugin_fetchPc_correctionReg <= 1'b0;
      IBusSimplePlugin_fetchPc_booted <= 1'b0;
      IBusSimplePlugin_fetchPc_inc <= 1'b0;
      IBusSimplePlugin_decodePc_pcReg <= 32'h0;
      _zz_56_ <= 1'b0;
      _zz_58_ <= 1'b0;
      IBusSimplePlugin_decompressor_bufferValid <= 1'b0;
      IBusSimplePlugin_decompressor_throw2BytesReg <= 1'b0;
      _zz_87_ <= 1'b0;
      IBusSimplePlugin_injector_nextPcCalc_valids_0 <= 1'b0;
      IBusSimplePlugin_injector_nextPcCalc_valids_1 <= 1'b0;
      IBusSimplePlugin_injector_nextPcCalc_valids_2 <= 1'b0;
      IBusSimplePlugin_injector_nextPcCalc_valids_3 <= 1'b0;
      IBusSimplePlugin_pending_value <= (3'b000);
      IBusSimplePlugin_rspJoin_rspBuffer_discardCounter <= (3'b000);
      CsrPlugin_mstatus_MIE <= 1'b0;
      CsrPlugin_mstatus_MPIE <= 1'b0;
      CsrPlugin_mstatus_MPP <= (2'b11);
      CsrPlugin_mie_MEIE <= 1'b0;
      CsrPlugin_mie_MTIE <= 1'b0;
      CsrPlugin_mie_MSIE <= 1'b0;
      CsrPlugin_interrupt_valid <= 1'b0;
      CsrPlugin_pipelineLiberator_pcValids_0 <= 1'b0;
      CsrPlugin_pipelineLiberator_pcValids_1 <= 1'b0;
      CsrPlugin_pipelineLiberator_pcValids_2 <= 1'b0;
      CsrPlugin_hadException <= 1'b0;
      execute_CsrPlugin_wfiWake <= 1'b0;
      _zz_118_ <= 1'b1;
      _zz_130_ <= 1'b0;
      memory_MulDivIterativePlugin_mul_counter_value <= 5'h0;
      memory_MulDivIterativePlugin_div_counter_value <= 5'h0;
      execute_arbitration_isValid <= 1'b0;
      memory_arbitration_isValid <= 1'b0;
      writeBack_arbitration_isValid <= 1'b0;
      memory_to_writeBack_REGFILE_WRITE_DATA <= 32'h0;
      memory_to_writeBack_INSTRUCTION <= 32'h0;
    end else begin
      if(IBusSimplePlugin_fetchPc_correction)begin
        IBusSimplePlugin_fetchPc_correctionReg <= 1'b1;
      end
      if((IBusSimplePlugin_fetchPc_output_valid && IBusSimplePlugin_fetchPc_output_ready))begin
        IBusSimplePlugin_fetchPc_correctionReg <= 1'b0;
      end
      IBusSimplePlugin_fetchPc_booted <= 1'b1;
      if((IBusSimplePlugin_fetchPc_correction || IBusSimplePlugin_fetchPc_pcRegPropagate))begin
        IBusSimplePlugin_fetchPc_inc <= 1'b0;
      end
      if((IBusSimplePlugin_fetchPc_output_valid && IBusSimplePlugin_fetchPc_output_ready))begin
        IBusSimplePlugin_fetchPc_inc <= 1'b1;
      end
      if(((! IBusSimplePlugin_fetchPc_output_valid) && IBusSimplePlugin_fetchPc_output_ready))begin
        IBusSimplePlugin_fetchPc_inc <= 1'b0;
      end
      if((IBusSimplePlugin_fetchPc_booted && ((IBusSimplePlugin_fetchPc_output_ready || IBusSimplePlugin_fetchPc_correction) || IBusSimplePlugin_fetchPc_pcRegPropagate)))begin
        IBusSimplePlugin_fetchPc_pcReg <= IBusSimplePlugin_fetchPc_pc;
      end
      if((decode_arbitration_isFiring && (! IBusSimplePlugin_decodePc_injectedDecode)))begin
        IBusSimplePlugin_decodePc_pcReg <= IBusSimplePlugin_decodePc_pcPlus;
      end
      if(_zz_174_)begin
        IBusSimplePlugin_decodePc_pcReg <= IBusSimplePlugin_jump_pcLoad_payload;
      end
      if(IBusSimplePlugin_iBusRsp_flush)begin
        _zz_56_ <= 1'b0;
      end
      if(_zz_54_)begin
        _zz_56_ <= (IBusSimplePlugin_iBusRsp_stages_0_output_valid && (! 1'b0));
      end
      if(IBusSimplePlugin_iBusRsp_flush)begin
        _zz_58_ <= 1'b0;
      end
      if(IBusSimplePlugin_iBusRsp_stages_1_output_ready)begin
        _zz_58_ <= (IBusSimplePlugin_iBusRsp_stages_1_output_valid && (! IBusSimplePlugin_iBusRsp_flush));
      end
      if((IBusSimplePlugin_decompressor_output_valid && IBusSimplePlugin_decompressor_output_ready))begin
        IBusSimplePlugin_decompressor_throw2BytesReg <= ((((! IBusSimplePlugin_decompressor_unaligned) && IBusSimplePlugin_decompressor_isInputLowRvc) && IBusSimplePlugin_decompressor_isInputHighRvc) || (IBusSimplePlugin_decompressor_bufferValid && IBusSimplePlugin_decompressor_isInputHighRvc));
      end
      if((IBusSimplePlugin_decompressor_output_ready && IBusSimplePlugin_decompressor_input_valid))begin
        IBusSimplePlugin_decompressor_bufferValid <= 1'b0;
      end
      if(_zz_183_)begin
        if(IBusSimplePlugin_decompressor_bufferFill)begin
          IBusSimplePlugin_decompressor_bufferValid <= 1'b1;
        end
      end
      if((IBusSimplePlugin_externalFlush || IBusSimplePlugin_decompressor_consumeCurrent))begin
        IBusSimplePlugin_decompressor_throw2BytesReg <= 1'b0;
        IBusSimplePlugin_decompressor_bufferValid <= 1'b0;
      end
      if(decode_arbitration_removeIt)begin
        _zz_87_ <= 1'b0;
      end
      if(IBusSimplePlugin_decompressor_output_ready)begin
        _zz_87_ <= (IBusSimplePlugin_decompressor_output_valid && (! IBusSimplePlugin_externalFlush));
      end
      if((! 1'b0))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_0 <= 1'b1;
      end
      if(IBusSimplePlugin_decodePc_flushed)begin
        IBusSimplePlugin_injector_nextPcCalc_valids_0 <= 1'b0;
      end
      if((! execute_arbitration_isStuck))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_1 <= IBusSimplePlugin_injector_nextPcCalc_valids_0;
      end
      if(IBusSimplePlugin_decodePc_flushed)begin
        IBusSimplePlugin_injector_nextPcCalc_valids_1 <= 1'b0;
      end
      if((! memory_arbitration_isStuck))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_2 <= IBusSimplePlugin_injector_nextPcCalc_valids_1;
      end
      if(IBusSimplePlugin_decodePc_flushed)begin
        IBusSimplePlugin_injector_nextPcCalc_valids_2 <= 1'b0;
      end
      if((! writeBack_arbitration_isStuck))begin
        IBusSimplePlugin_injector_nextPcCalc_valids_3 <= IBusSimplePlugin_injector_nextPcCalc_valids_2;
      end
      if(IBusSimplePlugin_decodePc_flushed)begin
        IBusSimplePlugin_injector_nextPcCalc_valids_3 <= 1'b0;
      end
      IBusSimplePlugin_pending_value <= IBusSimplePlugin_pending_next;
      IBusSimplePlugin_rspJoin_rspBuffer_discardCounter <= (IBusSimplePlugin_rspJoin_rspBuffer_discardCounter - _zz_228_);
      if(IBusSimplePlugin_iBusRsp_flush)begin
        IBusSimplePlugin_rspJoin_rspBuffer_discardCounter <= IBusSimplePlugin_pending_next;
      end
      CsrPlugin_interrupt_valid <= 1'b0;
      if(_zz_184_)begin
        if(_zz_185_)begin
          CsrPlugin_interrupt_valid <= 1'b1;
        end
        if(_zz_186_)begin
          CsrPlugin_interrupt_valid <= 1'b1;
        end
        if(_zz_187_)begin
          CsrPlugin_interrupt_valid <= 1'b1;
        end
      end
      if(CsrPlugin_pipelineLiberator_active)begin
        if((! execute_arbitration_isStuck))begin
          CsrPlugin_pipelineLiberator_pcValids_0 <= 1'b1;
        end
        if((! memory_arbitration_isStuck))begin
          CsrPlugin_pipelineLiberator_pcValids_1 <= CsrPlugin_pipelineLiberator_pcValids_0;
        end
        if((! writeBack_arbitration_isStuck))begin
          CsrPlugin_pipelineLiberator_pcValids_2 <= CsrPlugin_pipelineLiberator_pcValids_1;
        end
      end
      if(((! CsrPlugin_pipelineLiberator_active) || decode_arbitration_removeIt))begin
        CsrPlugin_pipelineLiberator_pcValids_0 <= 1'b0;
        CsrPlugin_pipelineLiberator_pcValids_1 <= 1'b0;
        CsrPlugin_pipelineLiberator_pcValids_2 <= 1'b0;
      end
      if(CsrPlugin_interruptJump)begin
        CsrPlugin_interrupt_valid <= 1'b0;
      end
      CsrPlugin_hadException <= CsrPlugin_exception;
      if(_zz_171_)begin
        case(CsrPlugin_targetPrivilege)
          2'b11 : begin
            CsrPlugin_mstatus_MIE <= 1'b0;
            CsrPlugin_mstatus_MPIE <= CsrPlugin_mstatus_MIE;
            CsrPlugin_mstatus_MPP <= CsrPlugin_privilege;
          end
          default : begin
          end
        endcase
      end
      if(_zz_172_)begin
        case(_zz_173_)
          2'b11 : begin
            CsrPlugin_mstatus_MPP <= (2'b00);
            CsrPlugin_mstatus_MIE <= CsrPlugin_mstatus_MPIE;
            CsrPlugin_mstatus_MPIE <= 1'b1;
          end
          default : begin
          end
        endcase
      end
      execute_CsrPlugin_wfiWake <= (({_zz_102_,{_zz_101_,_zz_100_}} != (3'b000)) || CsrPlugin_thirdPartyWake);
      _zz_118_ <= 1'b0;
      _zz_130_ <= (_zz_35_ && writeBack_arbitration_isFiring);
      memory_MulDivIterativePlugin_mul_counter_value <= memory_MulDivIterativePlugin_mul_counter_valueNext;
      memory_MulDivIterativePlugin_div_counter_value <= memory_MulDivIterativePlugin_div_counter_valueNext;
      if((! writeBack_arbitration_isStuck))begin
        memory_to_writeBack_REGFILE_WRITE_DATA <= _zz_48_;
      end
      if((! writeBack_arbitration_isStuck))begin
        memory_to_writeBack_INSTRUCTION <= memory_INSTRUCTION;
      end
      if(((! execute_arbitration_isStuck) || execute_arbitration_removeIt))begin
        execute_arbitration_isValid <= 1'b0;
      end
      if(((! decode_arbitration_isStuck) && (! decode_arbitration_removeIt)))begin
        execute_arbitration_isValid <= decode_arbitration_isValid;
      end
      if(((! memory_arbitration_isStuck) || memory_arbitration_removeIt))begin
        memory_arbitration_isValid <= 1'b0;
      end
      if(((! execute_arbitration_isStuck) && (! execute_arbitration_removeIt)))begin
        memory_arbitration_isValid <= execute_arbitration_isValid;
      end
      if(((! writeBack_arbitration_isStuck) || writeBack_arbitration_removeIt))begin
        writeBack_arbitration_isValid <= 1'b0;
      end
      if(((! memory_arbitration_isStuck) && (! memory_arbitration_removeIt)))begin
        writeBack_arbitration_isValid <= memory_arbitration_isValid;
      end
      if(execute_CsrPlugin_csr_768)begin
        if(execute_CsrPlugin_writeEnable)begin
          CsrPlugin_mstatus_MPP <= execute_CsrPlugin_writeData[12 : 11];
          CsrPlugin_mstatus_MPIE <= _zz_275_[0];
          CsrPlugin_mstatus_MIE <= _zz_276_[0];
        end
      end
      if(execute_CsrPlugin_csr_772)begin
        if(execute_CsrPlugin_writeEnable)begin
          CsrPlugin_mie_MEIE <= _zz_278_[0];
          CsrPlugin_mie_MTIE <= _zz_279_[0];
          CsrPlugin_mie_MSIE <= _zz_280_[0];
        end
      end
    end
  end

  always @ (posedge clk) begin
    if(IBusSimplePlugin_iBusRsp_stages_1_output_ready)begin
      _zz_59_ <= IBusSimplePlugin_iBusRsp_stages_1_output_payload;
    end
    if(_zz_183_)begin
      IBusSimplePlugin_decompressor_bufferData <= IBusSimplePlugin_decompressor_input_payload_rsp_inst[31 : 16];
    end
    if(IBusSimplePlugin_decompressor_output_ready)begin
      _zz_88_ <= IBusSimplePlugin_decompressor_output_payload_pc;
      _zz_89_ <= IBusSimplePlugin_decompressor_output_payload_rsp_error;
      _zz_90_ <= IBusSimplePlugin_decompressor_output_payload_rsp_inst;
      _zz_91_ <= IBusSimplePlugin_decompressor_output_payload_isRvc;
    end
    if(IBusSimplePlugin_injector_decodeInput_ready)begin
      IBusSimplePlugin_injector_formal_rawInDecode <= IBusSimplePlugin_decompressor_raw;
    end
    `ifndef SYNTHESIS
      `ifdef FORMAL
        assert((! (((dBus_rsp_ready && memory_MEMORY_ENABLE) && memory_arbitration_isValid) && memory_arbitration_isStuck)))
      `else
        if(!(! (((dBus_rsp_ready && memory_MEMORY_ENABLE) && memory_arbitration_isValid) && memory_arbitration_isStuck))) begin
          $display("FAILURE DBusSimplePlugin doesn't allow memory stage stall when read happend");
          $finish;
        end
      `endif
    `endif
    CsrPlugin_mip_MEIP <= externalInterrupt;
    CsrPlugin_mip_MTIP <= timerInterrupt;
    CsrPlugin_mip_MSIP <= softwareInterrupt;
    CsrPlugin_mcycle <= (CsrPlugin_mcycle + 64'h0000000000000001);
    if(writeBack_arbitration_isFiring)begin
      CsrPlugin_minstret <= (CsrPlugin_minstret + 64'h0000000000000001);
    end
    if(_zz_184_)begin
      if(_zz_185_)begin
        CsrPlugin_interrupt_code <= (4'b0111);
        CsrPlugin_interrupt_targetPrivilege <= (2'b11);
      end
      if(_zz_186_)begin
        CsrPlugin_interrupt_code <= (4'b0011);
        CsrPlugin_interrupt_targetPrivilege <= (2'b11);
      end
      if(_zz_187_)begin
        CsrPlugin_interrupt_code <= (4'b1011);
        CsrPlugin_interrupt_targetPrivilege <= (2'b11);
      end
    end
    if(_zz_171_)begin
      case(CsrPlugin_targetPrivilege)
        2'b11 : begin
          CsrPlugin_mcause_interrupt <= (! CsrPlugin_hadException);
          CsrPlugin_mcause_exceptionCode <= CsrPlugin_trapCause;
          CsrPlugin_mepc <= decode_PC;
        end
        default : begin
        end
      endcase
    end
    _zz_131_ <= _zz_34_[11 : 7];
    _zz_132_ <= _zz_33_;
    if(_zz_168_)begin
      if(_zz_170_)begin
        memory_MulDivIterativePlugin_rs2 <= (memory_MulDivIterativePlugin_rs2 >>> 2);
        memory_MulDivIterativePlugin_accumulator <= ({_zz_243_,memory_MulDivIterativePlugin_accumulator[31 : 0]} >>> 2);
      end
    end
    if((memory_MulDivIterativePlugin_div_counter_value == 5'h10))begin
      memory_MulDivIterativePlugin_div_done <= 1'b1;
    end
    if((! memory_arbitration_isStuck))begin
      memory_MulDivIterativePlugin_div_done <= 1'b0;
    end
    if(_zz_169_)begin
      if(_zz_181_)begin
        memory_MulDivIterativePlugin_rs1[31 : 0] <= memory_MulDivIterativePlugin_div_stage_1_outNumerator;
        memory_MulDivIterativePlugin_accumulator[31 : 0] <= memory_MulDivIterativePlugin_div_stage_1_outRemainder;
        if((memory_MulDivIterativePlugin_div_counter_value == 5'h10))begin
          memory_MulDivIterativePlugin_div_result <= _zz_263_[31:0];
        end
      end
    end
    if(_zz_182_)begin
      memory_MulDivIterativePlugin_accumulator <= 65'h0;
      memory_MulDivIterativePlugin_rs1 <= ((_zz_142_ ? (~ _zz_143_) : _zz_143_) + _zz_269_);
      memory_MulDivIterativePlugin_rs2 <= ((_zz_141_ ? (~ execute_RS2) : execute_RS2) + _zz_271_);
      memory_MulDivIterativePlugin_div_needRevert <= ((_zz_142_ ^ (_zz_141_ && (! execute_INSTRUCTION[13]))) && (! (((execute_RS2 == 32'h0) && execute_IS_RS2_SIGNED) && (! execute_INSTRUCTION[13]))));
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_RS1 <= decode_RS1;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_MEMORY_ADDRESS_LOW <= execute_MEMORY_ADDRESS_LOW;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_IS_DIV <= decode_IS_DIV;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_IS_DIV <= execute_IS_DIV;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_IS_RVC <= decode_IS_RVC;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_IS_RS2_SIGNED <= decode_IS_RS2_SIGNED;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC_USE_SUB_LESS <= decode_SRC_USE_SUB_LESS;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC_LESS_UNSIGNED <= decode_SRC_LESS_UNSIGNED;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_ENV_CTRL <= _zz_24_;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_ENV_CTRL <= _zz_21_;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_ENV_CTRL <= _zz_19_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC2_FORCE_ZERO <= decode_SRC2_FORCE_ZERO;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_ALU_CTRL <= _zz_17_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_REGFILE_WRITE_VALID <= decode_REGFILE_WRITE_VALID;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_REGFILE_WRITE_VALID <= execute_REGFILE_WRITE_VALID;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_REGFILE_WRITE_VALID <= memory_REGFILE_WRITE_VALID;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_PC <= decode_PC;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_PC <= _zz_28_;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_PC <= memory_PC;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_BYPASSABLE_MEMORY_STAGE <= decode_BYPASSABLE_MEMORY_STAGE;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_BYPASSABLE_MEMORY_STAGE <= execute_BYPASSABLE_MEMORY_STAGE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_BRANCH_CTRL <= _zz_14_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_IS_RS1_SIGNED <= decode_IS_RS1_SIGNED;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_REGFILE_WRITE_DATA <= _zz_44_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_BYPASSABLE_EXECUTE_STAGE <= decode_BYPASSABLE_EXECUTE_STAGE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_IS_CSR <= decode_IS_CSR;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC1_CTRL <= _zz_11_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_MEMORY_STORE <= decode_MEMORY_STORE;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_MEMORY_STORE <= execute_MEMORY_STORE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_INSTRUCTION <= decode_INSTRUCTION;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_INSTRUCTION <= execute_INSTRUCTION;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_IS_MUL <= decode_IS_MUL;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_IS_MUL <= execute_IS_MUL;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SHIFT_CTRL <= _zz_8_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_CSR_WRITE_OPCODE <= decode_CSR_WRITE_OPCODE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_CSR_READ_OPCODE <= decode_CSR_READ_OPCODE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_FORMAL_PC_NEXT <= decode_FORMAL_PC_NEXT;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_FORMAL_PC_NEXT <= _zz_49_;
    end
    if((! writeBack_arbitration_isStuck))begin
      memory_to_writeBack_FORMAL_PC_NEXT <= memory_FORMAL_PC_NEXT;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_SRC2_CTRL <= _zz_5_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_MEMORY_ENABLE <= decode_MEMORY_ENABLE;
    end
    if((! memory_arbitration_isStuck))begin
      execute_to_memory_MEMORY_ENABLE <= execute_MEMORY_ENABLE;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_ALU_BITWISE_CTRL <= _zz_2_;
    end
    if((! execute_arbitration_isStuck))begin
      decode_to_execute_RS2 <= decode_RS2;
    end
    if((! execute_arbitration_isStuck))begin
      execute_CsrPlugin_csr_768 <= (decode_INSTRUCTION[31 : 20] == 12'h300);
    end
    if((! execute_arbitration_isStuck))begin
      execute_CsrPlugin_csr_836 <= (decode_INSTRUCTION[31 : 20] == 12'h344);
    end
    if((! execute_arbitration_isStuck))begin
      execute_CsrPlugin_csr_772 <= (decode_INSTRUCTION[31 : 20] == 12'h304);
    end
    if((! execute_arbitration_isStuck))begin
      execute_CsrPlugin_csr_832 <= (decode_INSTRUCTION[31 : 20] == 12'h340);
    end
    if((! execute_arbitration_isStuck))begin
      execute_CsrPlugin_csr_834 <= (decode_INSTRUCTION[31 : 20] == 12'h342);
    end
    if(execute_CsrPlugin_csr_836)begin
      if(execute_CsrPlugin_writeEnable)begin
        CsrPlugin_mip_MSIP <= _zz_277_[0];
      end
    end
    if(execute_CsrPlugin_csr_832)begin
      if(execute_CsrPlugin_writeEnable)begin
        CsrPlugin_mscratch <= execute_CsrPlugin_writeData[31 : 0];
      end
    end
  end


endmodule
